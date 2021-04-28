import 'dart:convert';
import 'dart:io';

import '../database.dart';
import '../schema.dart';
import '../utils.dart';
import 'differentiator.dart';
import 'patcher.dart';

Future<void> runUpdateTool(List<String> args, DatabaseSchema schema) async {
  bool dryRun = args.contains('--dry-run');
  String? dbName = args.where((a) => a.startsWith('-db=')).map((a) => a.split('=')[1]).firstOrNull;
  bool applyChanges = args.contains('--apply-changes');

  if (dbName == null) {
    stdout.write('Select a database to update: ');
    dbName = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
  }

  var db = Database(debugPrint: false, dbName: dbName);

  await db.open();

  print('Getting schema changes of ${db.name}');
  print('=========================');

  var diff = await getSchemaDiff(db, schema);

  await db.startTransaction();

  if (diff.hasChanges) {
    diff.printDiff();
    print('=========================');

    if (dryRun) {
      print('DATABASE SCHEME HAS CHANGES, EXITING');
      db.cancelTransaction();
    } else {
      String? answerApplyChanges;
      if (!applyChanges) {
        stdout.write('Do you want to apply these changes? (yes/no): ');
        answerApplyChanges = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
      }

      if (applyChanges || answerApplyChanges == 'yes') {
        print('Database schema changed, applying updates now:');

        try {
          db.debugPrint = true;
          await patchSchema(db, diff);

          if (diff.tables.removed.isNotEmpty || diff.tables.modified.any((t) => t.columns.removed.isNotEmpty)) {
            print('=========================');
            print('The following changes would lead to data loss:');

            for (var table in diff.tables.removed) {
              print('-- TABLE ${table.name}');
            }
            for (var table in diff.tables.modified) {
              for (var column in table.columns.removed) {
                print('-- COLUMN ${table.name}.${column.name}');
              }
            }

            if (!applyChanges) {
              stdout.write('Do you want to continue anyways? (yes/no): ');
              var choose = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

              if (choose == 'yes') {
                await removeUnused(db, diff);
                print('---\nDATABASE UPDATE SUCCESSFUL');
              } else {
                db.cancelTransaction();
                print('---\nALL CHANGES REVERTED, EXITING');
              }
            } else {
              db.cancelTransaction();
              print('---\nALL CHANGES REVERTED, EXITING');
            }
          } else {
            print('---\nDATABASE UPDATE SUCCESSFUL');
          }
        } catch (_) {
          db.cancelTransaction();
        }
      } else {
        db.cancelTransaction();
      }
    }
  } else {
    print('NO CHANGES, ALL DONE');
  }
  print('========================');

  var updateWasSuccessFull = await db.finishTransaction();
  await db.close();

  exit(updateWasSuccessFull ? 0 : 1);
}