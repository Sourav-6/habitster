import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/white_logo.png');
  if (!file.existsSync()) {
    print('Logo not found at assets/images/white_logo.png!');
    return;
  }
  
  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    print('Failed to decode image.');
    return;
  }
  
  final int maxDim = image.width > image.height ? image.width : image.height;
  final int canvasSize = (maxDim * 1.6).toInt();
  
  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  
  final int offsetX = (canvasSize - image.width) ~/ 2;
  final int offsetY = (canvasSize - image.height) ~/ 2;
  
  img.compositeImage(canvas, image, dstX: offsetX, dstY: offsetY);
  
  final outFile = File('assets/images/white_logo_padded.png');
  outFile.writeAsBytesSync(img.encodePng(canvas));
  
  print('Padded image generated successfully at \${outFile.path}!');
}
