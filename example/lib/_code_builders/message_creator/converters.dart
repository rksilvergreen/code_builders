part of 'builder.dart';

final _dartObjectConverters = {
  MessageFormat: _messageFormatDartObjectConverter,
  Extra: _extraDartObjectConverter,
  Signature: _signatureDartObjectConverter,
  Message: _messageDartObjectConverter,
};

DartObjectConverter<MessageFormat> _messageFormatDartObjectConverter =
    DartObjectConverter<MessageFormat>((dartObject) => MessageFormat.values.firstWhere((e) {
          var value = RegExp(r"(?<=')[^']*(?=')").stringMatch(dartObject.toString());
          return e.name == value;
        }));

DartObjectConverter<Extra> _extraDartObjectConverter = DartObjectConverter<Extra>((dartObject) => Extra(
      prefix: dartObject.getFieldValue('prefix') as String,
      suffix: dartObject.getFieldValue('suffix') as String,
    ));

DartObjectConverter<Signature> _signatureDartObjectConverter = DartObjectConverter<Signature>((dartObject) => Signature(
      name: dartObject.getFieldValue('name') as String,
      isApproved: dartObject.getFieldValue('isApproved') as bool,
    ));

DartObjectConverter<Message> _messageDartObjectConverter = DartObjectConverter<Message>((dartObject) => Message(
      duplicates: dartObject.getFieldValue('duplicates') as int,
      format: dartObject.getFieldValue('format', [_messageFormatDartObjectConverter]) as MessageFormat,
      extra: dartObject.getFieldValue('extra', [_extraDartObjectConverter]) as Extra?,
      signatures: dartObject.getFieldValue('signatures', [_signatureDartObjectConverter]).cast<Signature>(),
    ));


