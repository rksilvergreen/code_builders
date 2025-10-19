part of code_builders;

class Car {
  final String name;
  final int year;
  final Engine engine;
  final Wheels wheels;

  const Car({required this.name, required this.year, required this.engine, required this.wheels});
}

class Engine {
  final String rotation;
  final int cylinders;
  final List<bool> valves;

  const Engine({required this.rotation, required this.cylinders, required this.valves});
}

class Wheels {
  final int size;
  final int type;
  final WheelsType wheelsType;
  final List<Maintenance> maintenance;

  const Wheels({required this.size, required this.type, required this.wheelsType, required this.maintenance});
}

class Maintenance {
  final int effort;
  final String description;

  const Maintenance({required this.effort, required this.description});
}

enum WheelsType {
  steel,
  aluminum,
  carbon,
}
