part of code_builders;

// extension CarDartObjectExtension on DartObject {
//   Car? getCar() => getValue(this) as Car?;

//   Engine? getEngine() => getValue(this) as Engine?;

//   Wheels? getWheels() => getValue(this) as Wheels?;

//   Maintenance? getMaintenance() => getValue(this) as Maintenance?;
// }

DartObjectConverter<Car> carDartObjectConverter = DartObjectConverter<Car>((dartObject) => Car(
      name: dartObject.getFieldValue('name') as String,
      year: dartObject.getFieldValue('year') as int,
      engine: dartObject.getFieldValue('engine', [engineDartObjectConverter]) as Engine,
      wheels: dartObject.getFieldValue('wheels', [wheelsDartObjectConverter]) as Wheels,
    ));

DartObjectConverter<Engine> engineDartObjectConverter = DartObjectConverter<Engine>((dartObject) => Engine(
      rotation: dartObject.getFieldValue('rotation') as String,
      cylinders: dartObject.getFieldValue('cylinders') as int,
      valves: dartObject.getFieldValue('valves') as List<bool>,
    ));

DartObjectConverter<Wheels> wheelsDartObjectConverter = DartObjectConverter<Wheels>((dartObject) => Wheels(
      size: dartObject.getFieldValue('size') as int,
      type: dartObject.getFieldValue('type') as int,
      wheelsType: dartObject.getFieldValue('wheelsType', [wheelsTypeDartObjectConverter]) as WheelsType,
      maintenance: dartObject.getFieldValue('maintenance', [maintenanceDartObjectConverter]) as List<Maintenance>,
    ));

DartObjectConverter<Maintenance> maintenanceDartObjectConverter =
    DartObjectConverter<Maintenance>((dartObject) => Maintenance(
          effort: dartObject.getFieldValue('effort') as int,
          description: dartObject.getFieldValue('description') as String,
        ));

DartObjectConverter<WheelsType> wheelsTypeDartObjectConverter = DartObjectConverter<WheelsType>(
    (dartObject) => WheelsType.values.firstWhere((e) => e.name == dartObject.toString()));
