import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flux/flux.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fsel;
import 'image_filters_controller.dart';

class ImageFiltersScreen extends StatefulWidget {
  const ImageFiltersScreen({super.key, required this.runtime});

  final FluxRuntime runtime;

  @override
  State<ImageFiltersScreen> createState() => _ImageFiltersScreenState();
}

class _ImageFiltersScreenState extends State<ImageFiltersScreen> {
  late ImageFiltersController _controller;

  final List<String> _filters = const [
    'none',
    'grayscale',
    'sepia',
    'gaussianBlur',
    'edgeDetect',
    // 'sharpen', // removed (not available in image ^4.5 API)
    'brightness',
    'contrast',
    'saturation',
    'hue',
    'motionBlur',
    'pixelate',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ImageFiltersController(widget.runtime);
    _generateSampleImage();
  }

  void _generateSampleImage() {
    // Generate a 256x256 gradient sample image to avoid external assets
    final image = img.Image(width: 256, height: 256);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final r = (x / image.width * 255).toInt();
        final g = (y / image.height * 255).toInt();
        final b = (((x + y) / (image.width + image.height)) * 255).toInt();
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(image));
    _controller.setOriginal(bytes);
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      _controller.setOriginal(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Filters Studio'),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final processing = _controller.isProcessing;
              return Row(
                children: [
                  if (processing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: IgnorePointer(
                      ignoring: processing,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Remote', label: Text('Remote')),
                          ButtonSegment(value: 'Local', label: Text('Local')),
                        ],
                        selected: {_controller.useRemote ? 'Remote' : 'Local'},
                        onSelectionChanged: (Set<String> selection) {
                          if (selection.isEmpty) return;
                          final choice = selection.first;
                          _controller.setUseRemote(choice == 'Remote');
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: MaterialStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final _processing = _controller.isProcessing;
            final _selectedFilter = _controller.filter;
            final _amount = _controller.amount;
            final _sigma = _controller.sigma;
            final _brightness = _controller.brightness;
            final _contrast = _controller.contrast;
            final _originalBytes = _controller.originalBytes;
            final _previewBytes = _controller.previewBytes;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _selectedFilter,
                        label: const Text('Filter'),
                        dropdownMenuEntries: _filters
                            .map((f) => DropdownMenuEntry(value: f, label: f))
                            .toList(),
                        onSelected: (v) {
                          if (v != null) _controller.setFilter(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _processing ? null : _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: (_previewBytes == null || _processing)
                          ? null
                          : () async {
                              final location = await fsel.getSaveLocation(
                                suggestedName: 'processed.png',
                                acceptedTypeGroups: [
                                  const fsel.XTypeGroup(
                                    label: 'PNG',
                                    extensions: ['png'],
                                  ),
                                ],
                              );
                              if (location == null) return;
                              final xfile = fsel.XFile.fromData(
                                _previewBytes,
                                name: 'processed.png',
                                mimeType: 'image/png',
                              );
                              await xfile.saveTo(location.path);
                            },
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedFilter == 'sepia')
                  _buildSlider(
                    'Amount',
                    _amount,
                    0.0,
                    5.0,
                    (v) => _controller.setAmount(v),
                  ),
                if (_selectedFilter == 'gaussianBlur')
                  _buildSlider(
                    'Sigma',
                    _sigma,
                    1.0,
                    16.0,
                    (v) => _controller.setSigma(v),
                  ),
                if (_selectedFilter == 'motionBlur') ...[
                  _buildSlider(
                    'Passes',
                    _amount,
                    1.0,
                    10.0,
                    (v) => _controller.setAmount(v),
                  ),
                  _buildSlider(
                    'Radius',
                    _sigma,
                    1.0,
                    16.0,
                    (v) => _controller.setSigma(v),
                  ),
                ],
                if (_selectedFilter == 'pixelate')
                  _buildSlider(
                    'Block size',
                    _amount,
                    2.0,
                    40.0,
                    (v) => _controller.setAmount(v),
                  ),
                if (_selectedFilter == 'brightness')
                  _buildSlider(
                    'Brightness',
                    _brightness,
                    0.0,
                    2.0,
                    (v) => _controller.setBrightness(v),
                  ),
                if (_selectedFilter == 'contrast')
                  _buildSlider(
                    'Contrast',
                    _contrast,
                    0.0,
                    2.0,
                    (v) => _controller.setContrast(v),
                  ),
                if (_selectedFilter == 'saturation')
                  _buildSlider(
                    'Saturation',
                    _controller.saturation,
                    0.0,
                    2.0,
                    (v) => _controller.setSaturation(v),
                  ),
                if (_selectedFilter == 'hue')
                  _buildSlider(
                    'Hue (deg)',
                    _controller.hue,
                    -180.0,
                    180.0,
                    (v) => _controller.setHue(v),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildImageCard('Original', _originalBytes),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImageCard('Preview', _previewBytes),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, Uint8List? bytes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: bytes == null
                    ? const Text('No image')
                    : Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool disabled = false,
  }) {
    // Clamp the incoming value to the slider's range to avoid assertion errors
    double displayValue = value;
    if (displayValue < min) displayValue = min;
    if (displayValue > max) displayValue = max;

    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: displayValue,
            min: min,
            max: max,
            onChanged: disabled ? null : onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            displayValue.toStringAsFixed(2),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
