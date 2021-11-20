import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class NewPlatform {
  static bool get isIOS => kIsWeb ? false : Platform.isIOS;

  static bool get isAndroid => kIsWeb ? false : Platform.isAndroid;

  static bool get isWeb => kIsWeb;
}

Future<void> showPlatformDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  if (NewPlatform.isIOS) {
    return showCupertinoDialog(
        context: context, builder: builder, barrierDismissible: false);
  } else {
    return showDialog(
        context: context, builder: builder, barrierDismissible: true);
  }
}

PageRoute platformPageRoute({required Widget Function(BuildContext) builder}) {
  if (NewPlatform.isIOS) {
    return CupertinoPageRoute(builder: builder);
  }
  return MaterialPageRoute(builder: builder);
}

abstract class PlatformWidget<C extends Widget, M extends Widget,
    W extends Widget?> extends StatelessWidget {
  PlatformWidget({Key? key}) : super(key: key);

  C buildCupertinoWidget(BuildContext context);
  M buildMaterialWidget(BuildContext context);
  W? buildWebWidget(BuildContext context) {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (NewPlatform.isIOS) {
        return buildCupertinoWidget(context);
      } else {
        return buildMaterialWidget(context);
      }
    } catch (e) {
      return buildWebWidget(context) ?? buildMaterialWidget(context);
    }
  }
}

class PlatformSwitch extends PlatformWidget<CupertinoSwitch, Switch, Null> {
  PlatformSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.highlightColor,
  }) : super(key: key);
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
    Key? key,
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
  }) : super(key: key);
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
    Key? key,
    this.title,
    this.content,
    this.actions,
  }) : super(key: key);
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
    Key? key,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.autoCorrect = true,
    this.textInputAction,
  }) : super(key: key);
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
      style: TextStyle(color: Theme.of(context).textTheme.bodyText2!.color),
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
      style: TextStyle(color: Theme.of(context).textTheme.bodyText2!.color),
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
    Key? key,
    this.child,
    this.isDefaultAction = false,
    this.onPressed,
    this.isDestructive = false,
  }) : super(key: key);
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
              : Theme.of(context).textTheme.bodyText2?.color,
        ),
      ),
    );
  }
}

class PlatformButton
    extends PlatformWidget<CupertinoButton, OutlinedButton, Null> {
  PlatformButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.disabledColor = Colors.transparent,
    this.color,
  }) : super(key: key);
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
            Theme.of(context).textTheme.bodyText2?.color),
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
    Key? key,
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
  }) : super(key: key);

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
    Key? key,
    required this.items,
    this.onSelectedItemChanged,
    required this.value,
    required this.arr,
  }) : super(key: key) {
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
    Key? key,
    required this.children,
    this.header,
  }) : super(key: key);
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
  PlatformFormField(
      {Key? key,
      required this.controller,
      this.validator,
      this.placeholder,
      this.keyboardType,
      this.prefix,
      this.obscureText = false})
      : super(key: key);
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
            color: Theme.of(context).textTheme.bodyText2?.color ??
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
        style: TextStyle(color: Theme.of(context).textTheme.bodyText2?.color));
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
  PlatformDatePicker(
      {Key? key,
      required this.minimumDate,
      required this.maximumDate,
      required this.onDateChanged})
      : super(key: key);
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
