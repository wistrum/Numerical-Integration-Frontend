import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numerical Integration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IntegrationPage(),
    );
  }
}

class IntegrationResult {
  final String function;
  final double lowerBound;
  final double upperBound;
  final String method;
  final String angularMeasure;
  final int intervals;  // Added intervals field to store with each result
  final double result;
  final DateTime timestamp;

  IntegrationResult({
    required this.function,
    required this.lowerBound,
    required this.upperBound,
    required this.method,
    required this.angularMeasure,
    required this.intervals,  // Store intervals with each result
    required this.result,
    required this.timestamp,
  });
}

class IntegrationPage extends StatefulWidget {
  const IntegrationPage({Key? key}) : super(key: key);

  @override
  State<IntegrationPage> createState() => _IntegrationPageState();
}

class _IntegrationPageState extends State<IntegrationPage> {
  final _functionController = TextEditingController();
  final _lowerBoundController = TextEditingController();
  final _upperBoundController = TextEditingController();
  final _intervalController = TextEditingController(text: '10');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedMethod = 'GAUSS_LEGENDRE_QUADRATURE';
  String _selectedAngularMeasure = 'RADIANS';
  bool _isLoading = false;
  final List<IntegrationResult> _results = [];

  final List<String> _methods = [
    'TRAPEZOIDAL',
    'SIMPSON',
    'MIDPOINT',
    'GAUSS_LEGENDRE_QUADRATURE',
  ];

  final List<String> _angularMeasures = [
    'RADIANS',
    'DEGREES',
    'GRADIANS',
  ];

  @override
  void dispose() {
    _functionController.dispose();
    _lowerBoundController.dispose();
    _upperBoundController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _calculateIntegral() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final int intervals = int.parse(_intervalController.text);

    try {
      final response = await http.post(
        Uri.parse('https://numerical-integration-api-production.up.railway.app/api/integrate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'integrationMethod': _selectedMethod,
          'function': _functionController.text,
          'lowerBound': double.parse(_lowerBoundController.text),
          'upperBound': double.parse(_upperBoundController.text),
          'intervals': intervals,  // Use local variable
          'angularMeasure': _selectedAngularMeasure,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results.add(IntegrationResult(
            function: _functionController.text,
            lowerBound: double.parse(_lowerBoundController.text),
            upperBound: double.parse(_upperBoundController.text),
            method: _selectedMethod,
            angularMeasure: _selectedAngularMeasure,
            intervals: intervals,  // Store intervals with the result
            result: data is double ? data : data['result'],
            timestamp: DateTime.now(),
          ));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _methodDisplayName(String method) {
    switch (method) {
      case 'TRAPEZOIDAL':
        return 'Trapezoidal Rule';
      case 'SIMPSON':
        return 'Simpson\'s Rule';
      case 'MIDPOINT':
        return 'Midpoint Rule';
      case 'GAUSS_LEGENDRE_QUADRATURE':
        return 'Gauss-Legendre Quadrature';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Numerical Integration - '),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse('https://github.com/wistrum/numerical-integration-api');
                if (!await launchUrl(url)) {
                  throw Exception('Could not launch $url');
                }
              },
              child: const Text(
                'Backend found here',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Integration Input Section
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Integration Parameters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Integral Visualization
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: _upperBoundController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Math.tex(
                                    '\\int',
                                    textStyle: const TextStyle(fontSize: 35),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: _lowerBoundController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _functionController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., x + sin(x^2)',
                                  border: UnderlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a function';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('dx', style: TextStyle(fontSize: 18)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Method selector
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Integration Method',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedMethod,
                          items: _methods.map((String method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(_methodDisplayName(method)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedMethod = newValue;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Angular Measure',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedAngularMeasure,
                          items: _angularMeasures.map((String measure) {
                            return DropdownMenuItem<String>(
                              value: measure,
                              child: Text(measure.toLowerCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedAngularMeasure = newValue;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Intervals
                        TextFormField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Number of Intervals',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the number of intervals';
                            }
                            final n = int.tryParse(value);
                            if (n == null || n <= 0) {
                              return 'Please enter a positive integer';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _calculateIntegral,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.calculate),
                            label: const Text('Calculate Integral'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Results Section
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _results.isEmpty
                              ? const Center(
                            child: Text(
                              'No results yet. Calculate an integral to see results here.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                              : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final result = _results[_results.length - 1 - index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '∫',
                                            style: TextStyle(
                                              fontSize: 24,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "${result.function} dx from ${result.lowerBound} to ${result.upperBound}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Method: ${_methodDisplayName(result.method)}",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        "Intervals: ${result.intervals}",  // Use stored intervals value
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        "Angular measure: ${result.angularMeasure.toLowerCase()}",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Result: ${result.result.toStringAsFixed(8)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            "${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}",
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}