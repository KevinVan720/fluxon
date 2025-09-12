import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flux/flux.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
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

  Future<void> _apply() async => _controller.apply();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Filters Studio'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _controller.useRemote ? 'Remote' : 'Local',
              items: const [
                DropdownMenuItem(value: 'Remote', child: Text('Remote')),
                DropdownMenuItem(value: 'Local', child: Text('Local')),
              ],
              onChanged: _controller.isProcessing
                  ? null
                  : (v) => _controller.setUseRemote(v == 'Remote'),
            ),
          ),
          const SizedBox(width: 8),
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
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(labelText: 'Filter'),
                        items: _filters
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (v) => _controller.setFilter(v ?? 'none'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _processing ? null : _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _processing ? null : _apply,
                      icon: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Apply'),
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
                    disabled: _processing,
                  ),
                if (_selectedFilter == 'gaussianBlur')
                  _buildSlider(
                    'Sigma',
                    _sigma,
                    1.0,
                    16.0,
                    (v) => _controller.setSigma(v),
                    disabled: _processing,
                  ),
                if (_selectedFilter == 'brightness')
                  _buildSlider(
                    'Brightness',
                    _brightness,
                    -1.0,
                    1.0,
                    (v) => _controller.setBrightness(v),
                    disabled: _processing,
                  ),
                if (_selectedFilter == 'contrast')
                  _buildSlider(
                    'Contrast',
                    _contrast,
                    -1.0,
                    1.0,
                    (v) => _controller.setContrast(v),
                    disabled: _processing,
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
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: disabled ? null : onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(value.toStringAsFixed(2), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
