import 'package:analyzer/dart/element/element.dart' show ClassElement, Element;
import 'package:build/build.dart' show BuildStep;
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:copy_with_extension_gen/src/helpers.dart';
import 'package:copy_with_extension_gen/src/settings.dart';
import 'package:source_gen/source_gen.dart'
    show ConstantReader, GeneratorForAnnotation, InvalidGenerationSourceError;

/// A `Generator` for `package:build_runner`
class CopyWithGenerator extends GeneratorForAnnotation<CopyWith> {
  CopyWithGenerator(this.settings) : super();

  Settings settings;

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Only classes can be annotated with "CopyWith". "$element" is not a ClassElement.',
        element: element,
      );
    }

    final ClassElement classElement = element;
    final privacyPrefix = element.isPrivate ? "_" : "";
    final classAnnotation = readClassAnnotation(settings, annotation);

    final sortedFields =
        sortedConstructorFields(classElement, classAnnotation.constructor);
    final typeParametersAnnotation = typeParametersString(classElement, false);
    final typeParametersNames = typeParametersString(classElement, true);
    final typeAnnotation = classElement.name + typeParametersNames;

    final constructorInput = sortedFields.fold<String>(
      '',
      (r, v) {
        if (v.fieldAnnotation.immutable) return r; // Skip the field
        return '$r ${v.name}: ${v.name},';
      },
    );

    return '''
    extension $privacyPrefix\$${classElement.name}CopyWith$typeParametersAnnotation on $typeAnnotation {
      $typeAnnotation rebuild(void Function($typeAnnotation) updates) {
        final result = $typeAnnotation(
          $constructorInput
        );
        updates(result);
        return result;
      }
    }
    ''';
  }
}
