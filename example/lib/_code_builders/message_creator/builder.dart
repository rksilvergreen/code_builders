import 'package:code_builders/code_builder.dart';
import 'annotations.dart';
import 'package:example/main.dart';

part 'converters.dart';

/////
Builder messageCreatorBuilder(BuilderOptions options) => CodeBuilder(
      name: 'message_creator',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/.gen/{{file}}.gen.message_creator.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        LibraryElement library = await buildStep.resolver.libraryFor(buildStep.inputId);

        // Collect all classes annotated with @Message
        List<ClassElement> messageClasses = library.getAllClassesAnnotatedWith<Message>();

        if (messageClasses.isEmpty) {
          return null;
        }

        // Create MessageManager class
        final buffer = StringBuffer();

        // Create the MessageManager class
        final messageManagerClass = Class(
          name: 'MessageManager',
          constructors: [
            Constructor(
              className: 'MessageManager',
              constructorName: 'tulu',
            ),
          ],
          getters: messageClasses.map((classElement) {
            final message = classElement.getAnnotationOf<Message>()!;

            final className = classElement.name;
            final getterName = '${className}Message';

            // Check if class implements Peelable
            final implementsPeelable =
                classElement.interfaces.any((interface) => interface.element.name == '${Peelable}');

            // Generate message content
            String messageContent;
            if (implementsPeelable) {
              messageContent = message.format == MessageFormat.elaborate
                  ? 'This fruit can be peeled and enjoyed as a healthy snack'
                  : 'Can be peeled';
            } else {
              messageContent =
                  message.format == MessageFormat.elaborate ? 'This fruit is ready to eat as is' : 'Ready to eat';
            }

            // Add prefix and suffix
            String fullMessage = messageContent;
            if (message.extra?.prefix != null) {
              fullMessage = '${message.extra!.prefix} $fullMessage';
            }
            if (message.extra?.suffix != null) {
              fullMessage = '$fullMessage ${message.extra!.suffix}';
            }

            // Repeat message based on duplicates
            final repeatedMessage = List.generate(message.duplicates, (_) => fullMessage).join(' ');

            return Getter(
              type: 'String',
              name: getterName,
              arrowFunction: true,
              body: (b) => b.write('"$repeatedMessage"'),
            );
          }).toList(),
        );

        messageManagerClass.writeToBuffer(buffer);

        return buffer;
      },
    );
