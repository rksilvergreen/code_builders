import 'package:code_builders/code_builder.dart';
import 'package:message_creator_annotations/annotations.dart';
// DartObjectConverters for annotation classes
// extension MessageDartObjectExtension on DartObject {
//   Message? getMessage() => getValue(this) as Message?;
//   Extra? getExtra() => getValue(this) as Extra?;
//   MessageFormat? getMessageFormat() => getValue(this) as MessageFormat?;
// }

DartObjectConverter<MessageFormat> messageFormatDartObjectConverter =
    DartObjectConverter<MessageFormat>((dartObject) => MessageFormat.values.firstWhere((e) {
          var value = RegExp(r"(?<=')[^']*(?=')").stringMatch(dartObject.toString());
          // print('e.name: ${e.name}');
          // print('value: $value');
          // print('e.name == value: ${e.name == value}');
          return e.name == value;
        }));

DartObjectConverter<Extra> extraDartObjectConverter = DartObjectConverter<Extra>((dartObject) => Extra(
      prefix: dartObject.getFieldValue('prefix') as String,
      suffix: dartObject.getFieldValue('suffix') as String,
    ));

DartObjectConverter<Signature> signatureDartObjectConverter = DartObjectConverter<Signature>((dartObject) => Signature(
      name: dartObject.getFieldValue('name') as String,
      isApproved: dartObject.getFieldValue('isApproved') as bool,
    ));

DartObjectConverter<Message> messageDartObjectConverter = DartObjectConverter<Message>((dartObject) => Message(
      duplicates: dartObject.getFieldValue('duplicates') as int,
      format: dartObject.getFieldValue('format', [messageFormatDartObjectConverter]) as MessageFormat,
      extra: dartObject.getFieldValue('extra', [extraDartObjectConverter]) as Extra?,
      signatures: dartObject.getFieldValue('signatures', [signatureDartObjectConverter]).cast<Signature>(),
    ));

final dartObjectConverters = {
  MessageFormat: messageFormatDartObjectConverter,
  Extra: extraDartObjectConverter,
  Signature: signatureDartObjectConverter,
  Message: messageDartObjectConverter,
};
