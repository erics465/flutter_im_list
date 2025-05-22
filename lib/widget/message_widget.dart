import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import '../models/message_model.dart';

//TODO: Future performance optimization: Move stateless messages (e.g. text) to different Widget class than stateful messages (e.g. survey)

typedef MessageWidgetBuilder = Widget Function(MessageModel message);
typedef OnBubbleClick = void Function(
    MessageModel message, BuildContext ancestor);

/// support text select
typedef HiSelectionArea = Widget Function(
    {required Text child, required MessageModel message});

class DefaultMessageWidget extends StatefulWidget {
  final MessageModel message;

  /// the font-family of the [content].
  final String? fontFamily;

  /// the font-size of the [content].
  final double fontSize;

  /// the size of the [avatar].
  final double avatarSize;

  /// the text-color of the [content].
  final Color? textColor;

  /// Background color of the message
  final Color? backgroundColor;
  final MessageWidgetBuilder? messageWidget;

  /// Called when the user taps this part of the material.
  final OnBubbleClick? onBubbleTap;

  /// Called when the user long-presses on this part of the material.
  final OnBubbleClick? onBubbleLongPress;

  final HiSelectionArea? hiSelectionArea;

  final Function? setStateRef;

  const DefaultMessageWidget(
      {required GlobalKey key,
      required this.message,
      this.fontFamily,
      this.fontSize = 16.0,
      this.textColor,
      this.backgroundColor,
      this.messageWidget,
      this.avatarSize = 40,
      this.onBubbleTap,
      this.onBubbleLongPress,
      this.hiSelectionArea,
      this.setStateRef})
      : super(key: key);

  @override
  State<DefaultMessageWidget> createState() => _DefaultMessageWidgetState();
}

class _DefaultMessageWidgetState extends State<DefaultMessageWidget> {

  double get contentMargin => widget.avatarSize + 10;

  int radioOption = 0;

  String get senderInitials {
    if (widget.message.ownerName == null) return "";
    List<String> chars = widget.message.ownerName!.split(" ");
    if (chars.length > 1) {
      return chars[0];
    } else {
      return widget.message.ownerName![0];
    }
  }

  Widget get _buildCircleAvatar {
    var child = widget.message.avatar is String
        ? ClipOval(
            child: Image.network(
              widget.message.avatar!,
              height: widget.avatarSize,
              width: widget.avatarSize,
            ),
          )
        : CircleAvatar(
            radius: 20,
            child: Text(
              senderInitials,
              style: const TextStyle(fontSize: 16),
            ));
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messageWidget != null) {
      return widget.messageWidget!(widget.message);
    }

    Widget content;
    if (widget.message.ownerType == OwnerType.system) {
      if (widget.message.mediaType == MediaType.text) {
        content = _parseSystemMessage(context);
      } else {
        content = _buildContentLive(context);
      }
    } else {
      content = widget.message.ownerType == OwnerType.receiver
          ? _buildReceiver(context)
          : _buildSender(context);
    }
    return Column(
      children: [
        //if (message.showCreatedTime) _buildCreatedTime(),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: content,
        ),
      ],
    );
  }

  Widget _buildReceiver(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        _buildCircleAvatar,
        Flexible(
          child: Bubble(
              margin: BubbleEdges.fromLTRB(10, 0, contentMargin, 0),
              stick: true,
              nip: BubbleNip.leftTop,
              color: widget.backgroundColor ?? const Color.fromRGBO(233, 232, 252, 10),
              alignment: Alignment.topLeft,
              child: _buildMessage(TextAlign.left, context)
          ),
        ),
      ],
    );
  }

  Widget _buildSender(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Bubble(
              margin: BubbleEdges.fromLTRB(contentMargin, 0, 10, 0),
              stick: true,
              nip: BubbleNip.rightTop,
              color: widget.backgroundColor ?? Colors.white,
              alignment: Alignment.topRight,
              child: _buildMessage(TextAlign.right, context)),
        ),
        _buildCircleAvatar
      ],
    );
  }

  Widget _buildMessage(TextAlign align, BuildContext context) {
    return switch (widget.message.mediaType) {
      MediaType.text => _buildContentText(align, context),
      MediaType.survey => _buildContentSurvey(align, context),
      MediaType.image => _buildContentImage(align, context),
      MediaType.location => _buildContentLocation(align, context),
      _ => _buildContentText(align, context) //TODO
    };
  }

  Widget _buildContentText(TextAlign align, BuildContext context) {
    Widget text = Text(
      widget.message.content,
      textAlign: align,
      style: TextStyle(
          fontSize: widget.fontSize,
          color: widget.textColor ?? Colors.black,
          fontFamily: widget.fontFamily),
    );
    if (widget.hiSelectionArea != null) {
      text = widget.hiSelectionArea!.call(child: text as Text, message: widget.message);
    }
    return InkWell(
        onTap: () =>
            widget.onBubbleTap != null ? widget.onBubbleTap!(widget.message, context) : null,
        onLongPress: () => widget.onBubbleLongPress != null
            ? widget.onBubbleLongPress!(widget.message, context)
            : null,
        child: text);
  }

  Widget _buildContentImage(TextAlign align, BuildContext context) {
    Widget image = Image.network("https://picsum.photos/200/200", height: 150, fit: BoxFit.cover);
    return InkWell(
        onTap: () =>
          widget.onBubbleTap != null ? widget.onBubbleTap!(widget.message, context) : {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return Dialog.fullscreen(
                  child: Stack(
                    children: [
                      //Image
                      Center(
                        child: Image.network("https://picsum.photos/200/200",
                          width: double.infinity,
                          fit: BoxFit.cover),
                      ),
                      //Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      )
                    ]
                  )
                );
              },
            )
          },
        onLongPress: () => widget.onBubbleLongPress != null
            ? widget.onBubbleLongPress!(widget.message, context)
            : null,
        child: image,
    );
  }

  Widget _buildContentLocation(TextAlign align, BuildContext context) {
    Widget text = FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(51.509364, -0.128928), // Center the map over London
        initialZoom: 9.2,
      ),
      children: [
        TileLayer( // Bring your own tiles
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
          userAgentPackageName: 'eu.kiwio.takepart', // Add your app identifier
          // And many more recommended properties!
        ),
        const MarkerLayer(
          markers: [
            // Activity markers
            Marker(
              point: LatLng(51.0, 49.0),
              width: 80,
              height: 80,
              child: Icon(Icons.location_on),
            ),
          ],
        ),
        RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => {}, // (external)
            ),
            // Also add images...
          ],
        ),
      ],
    );
    return InkWell(
        onTap: () =>
            widget.onBubbleTap != null ? widget.onBubbleTap!(widget.message, context) : null,
        onLongPress: () => widget.onBubbleLongPress != null
            ? widget.onBubbleLongPress!(widget.message, context)
            : null,
        child: Container(
          height: 175,
          child: text
    ));
  }

  Widget _buildContentSurvey(TextAlign textAlign, BuildContext context) {
    Widget survey = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Survey title",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (BuildContext context, int index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: RadioListTile(value: index,
                    groupValue: radioOption,
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        radioOption = value!;
                      });
                    },
                    title: Text("Option $index")),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () => {}, icon: const Icon(Icons.remove)),
                    IconButton(onPressed: () => {}, icon: const Icon(Icons.edit))
                  ]
                )
              ],
            );
          }
        )
      ],
    );

    return InkWell(
        onTap: () =>
            widget.onBubbleTap != null ? widget.onBubbleTap!(widget.message, context) : null,
        onLongPress: () => widget.onBubbleLongPress != null
            ? widget.onBubbleLongPress!(widget.message, context)
            : null,
        child: survey);
  }

  Widget _parseSystemMessage(BuildContext context) {
    return _buildSystemMessage(widget.message.content);
  }

  Widget _buildSystemMessage(String text) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text),
    );
  }

  Widget _buildContentLive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: const Text("Live safety information goes here"),
    );
  }
}
