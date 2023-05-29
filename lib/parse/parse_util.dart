import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

typedef ParseObjectCreator<T extends ParseObject> = T Function();

int prevNewLocalObjectID = 0;
String getNewLocalObjectID() {
  var newLocalObjectID = DateTime.now().millisecondsSinceEpoch;
  if (newLocalObjectID <= prevNewLocalObjectID) {
    newLocalObjectID = prevNewLocalObjectID + 1;
  }
  prevNewLocalObjectID = newLocalObjectID;
  return newLocalObjectID.toRadixString(35);
}

class ParseList {
  static const String lastChangeTimeKey = 'LastChangeTime'; // millisecondsSinceEpoch в момент изменения, на данном устройстве

  /// Считывает список объектов из локального хранилища
  static Future<List<T>> getLocal<T extends ParseObject>(String listName, ParseObjectCreator<T> creator) async {
    final prefs = await SharedPreferences.getInstance();
    final objectIDList = prefs.getStringList(listName) ?? [];

    final retList = <T>[];

    for (var objectID in objectIDList) {
      final object = creator();
      await object.fromPin(objectID);
      retList.add(object);
    }
    return retList;
  }

  /// Записывает список объектов в локальное хранилище
  /// ParseObject длжен иметь поле int lastChangeTime = millisecondsSinceEpoch от последнего изменения
  /// Возвращает максимальный lastChangeTime
  static Future<int> saveLocal(List<ParseObject> objectList, String listName,
      int fromChangeTime) async {
    var lastID = DateTime
        .now()
        .millisecondsSinceEpoch;

    final objectIDList = <String>[];

    int maxLastChangeTime = 0;

    for (var object in objectList) {
      final objectLastChangeTime = object.get<int>(lastChangeTimeKey) ?? 0;

      if (object.objectId == null || object.objectId!.isEmpty) {
        object.objectId = '${object.parseClassName}/${lastID.toRadixString(35)}';
        await object.pin();
        lastID++;
      } else {
        if (objectLastChangeTime > fromChangeTime) {
          await object.pin();
        }
      }

      if (maxLastChangeTime < objectLastChangeTime) {
        maxLastChangeTime = objectLastChangeTime;
      }

      objectIDList.add(object.objectId!);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(listName, objectIDList);

    return maxLastChangeTime;
  }

  static Future<void> deleteLocal(List<ParseObject> objectList, String listName) async {
    for (var object in objectList) {
      object.unpin();
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.remove(listName);
  }

  /// Синхронизация списков локальных данных и данных на сервере
  /// ParseObject длжен иметь поле int lastChangeTime = millisecondsSinceEpoch от последнего изменения
  static Future<bool> synchronizeLists(
      List<ParseObject> localObjectList,
      List<ParseObject> serverObjectList,
      {
        List<ParseObject>? newObjectList,
        List<ParseObject>? changedObjectList,
        List<ParseObject>? deletedObjectList
      }
  ) async {
    bool localSaveNeed = false;

    final toRemove = <ParseObject>[];
    final toAdd = <ParseObject>[];

    // записи сохранённые только локально - сохраняем на сервер
    for (var localObject in localObjectList) {
      if (localObject.objectId == null || localObject.objectId!.isEmpty) {
        // Новый объект создан локально и ещё не сохранялся ни локально ни на сервер
        await localObject.save();
        await localObject.pin();
        localSaveNeed = true;
      } else {
        if (localObject.objectId!.indexOf('${localObject.parseClassName}/') == 0 ) {
          // Объект был создан и сохранён локально и ещё не сохранялся на сервер
          await localObject.unpin();
          localObject.objectId = null;
          await localObject.save();
          await localObject.pin();
          localSaveNeed = true;
        } else {
          if (!serverObjectList.any((serverObject) => serverObject.objectId == localObject.objectId)) {
            // Объект был ранее сохранён на сервер, но теперь его на сервере нету -> удаляем локальный объект
            toRemove.add(localObject);
          }
        }
      }
    }

    // обновляем сервер, если что то локально было обновлено позже чем на сервере
    // + наоборот
    for (var localObject in localObjectList) {
      final serverObject = serverObjectList.firstWhereOrNull((serverObject) => serverObject.objectId == localObject.objectId);

      if (serverObject == null) {
        await localObject.save();
      } else {
        final serverObjectLastChangeTime = serverObject.get<int>(lastChangeTimeKey) ?? 0;
        final localObjectLastChangeTime = localObject.get<int>(lastChangeTimeKey) ?? 0;

        if (serverObjectLastChangeTime > localObjectLastChangeTime) {
          // обновляем локальный объект состоянием получнным с сервера
          localObject.fromJson(serverObject.toJson());
          localSaveNeed = true;
          if (changedObjectList != null) changedObjectList.add(localObject);
        } else {
          // сохраняем изменения в локальном объекте на сервер
          await localObject.save();
        }
      }
    }

    // добавляем новые записи появившиеся на сервере
    for (var serverObject in serverObjectList) {
      final localObject = localObjectList.firstWhereOrNull((localObject) => localObject.objectId == serverObject.objectId);
      if (localObject == null) {
        toAdd.add(serverObject);
      }
    }

    for (var localObject in toRemove) {
      await localObject.unpin();
      localObjectList.remove(localObject);
      localSaveNeed = true;
      if (deletedObjectList != null) deletedObjectList.add(localObject);
    }

    for (var serverObject in toAdd) {
      await serverObject.pin();
      localObjectList.add(serverObject);
      localSaveNeed = true;
      if (newObjectList != null) newObjectList.add(serverObject);
    }

    return localSaveNeed;
  }

  /// Возвращает максимальный lastChangeTime в списке объектов
  /// ParseObject длжен иметь поле int lastChangeTime = millisecondsSinceEpoch от последнего изменения
  static int getMaxLastChangeTime(List<ParseObject> objectList) {
    int maxLastChangeTime = 0;

    for (var object in objectList) {
      final objectLastChangeTime = object.get<int>(lastChangeTimeKey) ?? 0;
      if (maxLastChangeTime < objectLastChangeTime) {
        maxLastChangeTime = objectLastChangeTime;
      }
    }
    return maxLastChangeTime;
  }

  /// Записывает список объектов на сервер
  /// ParseObject длжен иметь поле int lastChangeTime = millisecondsSinceEpoch от последнего изменения
  /// Возвращает максимальный lastChangeTime
  static Future<int> saveServer(List<ParseObject> objectList, int fromChangeTime) async {
    int maxLastChangeTime = 0;

    for (var object in objectList) {
      final objectLastChangeTime = object.get<int>(lastChangeTimeKey) ?? 0;

      if (objectLastChangeTime > fromChangeTime) {
        if (object.objectId != null && object.objectId!.indexOf('${object.parseClassName}/') == 0) {
          await object.unpin();
          object.objectId = null;
          await object.save();
          await object.pin();
        } else {
          await object.save();
        }
      }

      if (maxLastChangeTime < objectLastChangeTime) {
        maxLastChangeTime = objectLastChangeTime;
      }
    }

    return maxLastChangeTime;
  }

  /// Считывает изменённые/новые объекты
  static Future<void> updateFromServer(List<ParseObject> objectList) async {

  }
}
