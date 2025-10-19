import 'package:example/_code_builders/message_creator/annotations.dart';

abstract class Fruit {}

abstract interface class Peelable {
  void peel();
}

@Message(
  duplicates: 2,
  format: MessageFormat.concise,
  extra: Extra(
    prefix: 'Start',
    suffix: 'End',
  ),
  signatures: [Signature(name: 'Kyle', isApproved: true), Signature(name: 'Josh', isApproved: false)],
)
class Apple extends Fruit {}

@Message(
  duplicates: 1,
  format: MessageFormat.elaborate,
  signatures: [Signature(name: 'Anna', isApproved: true), Signature(name: 'Bar', isApproved: true)],
)
class Banana extends Fruit implements Peelable {
  
  @override
  void peel() {
    print('Banana is being peeled');
  }
}


