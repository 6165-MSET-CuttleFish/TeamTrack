import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Error-free platform accessor
class NewPlatform {
  static bool get isIOS => kIsWeb ? false : Platform.isIOS;

  static bool get isAndroid => kIsWeb ? false : Platform.isAndroid;

  static bool get isWeb => kIsWeb;
}

/// Platform-specific alert dialogs
Future<void> showPlatformDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool? barrierDismissible,
}) =>
    NewPlatform.isIOS
        ? showCupertinoDialog(
            context: context,
            builder: builder,
            barrierDismissible: barrierDismissible ?? false,
          )
        : showDialog(
            context: context,
            builder: builder,
            barrierDismissible: barrierDismissible ?? true,
          );

PageRoute platformPageRoute({required Widget Function(BuildContext) builder}) =>
    NewPlatform.isIOS
        ? CupertinoPageRoute(builder: builder)
        : MaterialPageRoute(builder: builder);

PageRoute expandPageRoute({required Widget Function(BuildContext) builder}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.linear;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return FadeTransition(
        opacity: offsetAnimation,
        child: child,
      );
    },
  );
}

abstract class PlatformWidget<C extends Widget, M extends Widget,
    W extends Widget?> extends StatelessWidget {
  PlatformWidget({super.key});

  C buildCupertinoWidget(BuildContext context);
  M buildMaterialWidget(BuildContext context);
  W? buildWebWidget(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    if (NewPlatform.isIOS) {
      return buildCupertinoWidget(context);
    } else if (NewPlatform.isAndroid) {
      return buildMaterialWidget(context);
    } else {
      return buildWebWidget(context) ?? buildMaterialWidget(context);
    }
  }
}

class PlatformSwitch extends PlatformWidget<CupertinoSwitch, Switch, Null> {
  PlatformSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.highlightColor,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? highlightColor;
  @override
  CupertinoSwitch buildCupertinoWidget(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: highlightColor ?? Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Switch buildMaterialWidget(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: highlightColor ?? Theme.of(context).colorScheme.primary,
    );
  }
}

class PlatformText extends PlatformWidget<Text, Text, SelectableText> {
  PlatformText(
    this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });
  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  Text buildCupertinoWidget(BuildContext context) => Text(
        text,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );

  @override
  Text buildMaterialWidget(context) => buildCupertinoWidget(context);

  @override
  SelectableText buildWebWidget(BuildContext context) => SelectableText(
        text,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
}

class PlatformAlert
    extends PlatformWidget<CupertinoAlertDialog, AlertDialog, Null> {
  PlatformAlert({
    super.key,
    this.title,
    this.content,
    this.actions,
  });
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  @override
  CupertinoAlertDialog buildCupertinoWidget(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        child: title,
        padding: EdgeInsets.only(bottom: 10),
      ),
      content: content,
      actions: actions!,
    );
  }

  @override
  AlertDialog buildMaterialWidget(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      title: title,
      content: content,
      actions: actions,
    );
  }
}

class PlatformTextField
    extends PlatformWidget<CupertinoTextField, TextFormField, Null> {
  PlatformTextField({
    super.key,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.autoCorrect = true,
    this.textInputAction,
  });
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final bool autoCorrect;
  final TextInputAction? textInputAction;
  @override
  CupertinoTextField buildCupertinoWidget(BuildContext context) {
    return CupertinoTextField(
      textInputAction: textInputAction,
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      placeholder: placeholder,
      obscureText: obscureText,
      autocorrect: autoCorrect,
    );
  }

  @override
  TextFormField buildMaterialWidget(BuildContext context) {
    return TextFormField(
      textInputAction: textInputAction,
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: placeholder),
      obscureText: obscureText,
      autocorrect: autoCorrect,
    );
  }
}

class PlatformDialogAction
    extends PlatformWidget<CupertinoDialogAction, TextButton, Null> {
  PlatformDialogAction({
    super.key,
    this.child,
    this.isDefaultAction = false,
    this.onPressed,
    this.isDestructive = false,
  });
  final Widget? child;
  final bool isDefaultAction;
  final void Function()? onPressed;
  final bool isDestructive;
  @override
  CupertinoDialogAction buildCupertinoWidget(BuildContext context) {
    return CupertinoDialogAction(
      isDefaultAction: isDefaultAction,
      child: child!,
      onPressed: onPressed,
      isDestructiveAction: isDestructive,
    );
  }

  @override
  TextButton buildMaterialWidget(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: child!,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(
          isDestructive
              ? Colors.red
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

class PlatformButton
    extends PlatformWidget<CupertinoButton, OutlinedButton, Null> {
  PlatformButton({
    super.key,
    required this.child,
    this.onPressed,
    this.disabledColor = Colors.transparent,
    this.color,
  });
  final Widget child;
  final void Function()? onPressed;
  final Color? color;
  final Color disabledColor;
  @override
  CupertinoButton buildCupertinoWidget(BuildContext context) {
    return CupertinoButton(
      borderRadius: BorderRadius.all(Radius.circular(50)),
      child: child,
      onPressed: onPressed,
      color: color,
      disabledColor: disabledColor,
    );
  }

  @override
  OutlinedButton buildMaterialWidget(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          color?.withOpacity(0.6),
        ),
        foregroundColor: MaterialStateProperty.all(
            Theme.of(context).textTheme.bodyMedium?.color),
        side: MaterialStateProperty.all(
          BorderSide(color: color ?? Colors.transparent),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.elliptical(100, 100),
            ),
          ),
        ),
      ),
    );
  }
}

class PlatformSlider extends PlatformWidget<CupertinoSlider, Slider, Null> {
  PlatformSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.mouseCursor,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
  });

  final double value;
  final void Function(double)? onChanged;
  final void Function(double)? onChangeStart;
  final void Function(double)? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final MouseCursor? mouseCursor;
  final String Function(double)? semanticFormatterCallback;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  CupertinoSlider buildCupertinoWidget(BuildContext context) {
    return CupertinoSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
      thumbColor: thumbColor ?? CupertinoColors.white,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }

  @override
  Slider buildMaterialWidget(BuildContext context) {
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
      focusNode: focusNode,
      autofocus: autofocus,
      label: label,
      semanticFormatterCallback: semanticFormatterCallback,
      mouseCursor: mouseCursor,
      inactiveColor: inactiveColor,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }
}

class PlatformProgressIndicator extends PlatformWidget<
    CupertinoActivityIndicator, CircularProgressIndicator, Null> {
  @override
  CupertinoActivityIndicator buildCupertinoWidget(BuildContext context) =>
      CupertinoActivityIndicator();

  @override
  CircularProgressIndicator buildMaterialWidget(BuildContext context) =>
      CircularProgressIndicator();
}

class PlatformPicker<T>
    extends PlatformWidget<CupertinoPicker, DropdownButton, Null> {
  PlatformPicker({
    super.key,
    required this.items,
    this.onSelectedItemChanged,
    required this.value,
    required this.arr,
  }) {
    for (int i = 0; i < arr.length; i++) {
      dropdownItems.add(
        DropdownMenuItem<T>(
          child: items[i],
          value: arr[i],
        ),
      );
    }
  }
  final void Function(dynamic)? onSelectedItemChanged;
  final List<Widget> items;
  final List<T> arr;
  final T value;
  final List<DropdownMenuItem<T>> dropdownItems = [];

  @override
  CupertinoPicker buildCupertinoWidget(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 40,
      onSelectedItemChanged: onSelectedItemChanged,
      children: items.map((i) => Center(child: i)).toList(),
    );
  }

  @override
  DropdownButton buildMaterialWidget(BuildContext context) {
    return DropdownButton<T>(
      items: dropdownItems,
      onChanged: onSelectedItemChanged,
      value: value,
    );
  }
}

class PlatformForm extends PlatformWidget<CupertinoFormSection, Form, Null> {
  PlatformForm({
    super.key,
    required this.children,
    this.header,
  });
  final List<Widget> children;
  final Widget? header;
  @override
  CupertinoFormSection buildCupertinoWidget(BuildContext context) {
    return CupertinoFormSection(
      children: children,
      key: key,
      header: header,
    );
  }

  @override
  Form buildMaterialWidget(BuildContext context) {
    return Form(
      key: key,
      child: Column(
        children: [if (header != null) header!, ...children],
      ),
    );
  }
}

class PlatformFormField
    extends PlatformWidget<CupertinoTextFormFieldRow, TextFormField, Null> {
  PlatformFormField({
    super.key,
    required this.controller,
    this.validator,
    this.placeholder,
    this.keyboardType,
    this.prefix,
    this.obscureText = false,
  });
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final bool obscureText;
  @override
  CupertinoTextFormFieldRow buildCupertinoWidget(BuildContext context) {
    return CupertinoTextFormFieldRow(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).textTheme.bodyMedium?.color ??
                Colors.deepPurple,
            width: 1,
          ),
        ),
        controller: controller,
        validator: validator,
        placeholder: placeholder,
        keyboardType: keyboardType,
        prefix: prefix,
        obscureText: obscureText,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color));
  }

  @override
  TextFormField buildMaterialWidget(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(labelText: placeholder),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }
}

class PlatformDatePicker
    extends PlatformWidget<CupertinoDatePicker, CalendarDatePicker, Null> {
  PlatformDatePicker({
    super.key,
    required this.minimumDate,
    required this.maximumDate,
    required this.onDateChanged,
  });
  final DateTime maximumDate, minimumDate;
  final void Function(DateTime) onDateChanged;
  @override
  CupertinoDatePicker buildCupertinoWidget(BuildContext context) =>
      CupertinoDatePicker(
        onDateTimeChanged: onDateChanged,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );

  @override
  CalendarDatePicker buildMaterialWidget(BuildContext context) =>
      CalendarDatePicker(
          initialDate: maximumDate,
          firstDate: minimumDate,
          lastDate: maximumDate,
          onDateChanged: onDateChanged);
}
