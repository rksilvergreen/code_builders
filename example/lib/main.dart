import 'package:message_creator_annotations/annotations.dart';

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
)
class Apple extends Fruit {}

@Message(
  duplicates: 1,
  format: MessageFormat.elaborate,
)
class Banana extends Fruit implements Peelable {
  
  @override
  void peel() {
    print('Banana is being peeled');
  }
}


