import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const PerguntaApp());

class PerguntaApp extends StatelessWidget {
  const PerguntaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PerguntaScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PerguntaScreen extends StatefulWidget {
  @override
  _PerguntaScreenState createState() => _PerguntaScreenState();
}

class _PerguntaScreenState extends State<PerguntaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Color _themeColor = Colors.grey.shade300;
  int _currentQuestionIndex = 0;
  String _userName = '';
  final List<String> _perguntas = [
    'Qual a cor que você mais gosta?',
    'Digite seu nome:',
    'Qual o seu animal favorito?',
    'Qual o seu hobby preferido?',
    'Qual cidade você gostaria de visitar?',
    'Qual sua comida favorita?',
    'Prefere livros ou filmes?',
    'Qual o melhor horário do dia para você?',
    'Qual é o seu esporte favorito?',
    'Descreva um sonho que você tem:',
  ];
  final List<List<String>> _opcoes = [
    ['Azul', 'Amarelo', 'Vermelho', 'Verde'],
    [], // Campo aberto
    ['Cachorro', 'Gato', 'Pássaro', 'Peixe'],
    ['Ler', 'Viajar', 'Cozinhar', 'Praticar esportes'],
    ['Paris', 'Nova York', 'Tóquio', 'Rio de Janeiro'],
    ['Pizza', 'Hambúrguer', 'Sushi', 'Salada'],
    ['Livros', 'Filmes'],
    ['Manhã', 'Tarde', 'Noite'],
    ['Futebol', 'Basquete', 'Natação', 'Ciclismo'],
    [], // Campo aberto
  ];

  final Map<int, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _updateThemeColor(String? answer) {
    if (_currentQuestionIndex == 0) {
      setState(() {
        switch (answer) {
          case 'Azul':
            _themeColor = Colors.blue.shade100;
            break;
          case 'Amarelo':
            _themeColor = Colors.yellow.shade100;
            break;
          case 'Vermelho':
            _themeColor = Colors.red.shade100;
            break;
          case 'Verde':
            _themeColor = Colors.green.shade100;
            break;
          default:
            _themeColor = Colors.grey.shade300;
        }
      });
    }
  }

  void _onAnswerSelected(dynamic answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;

      // Atualiza o nome após a segunda pergunta
      if (_currentQuestionIndex == 1) {
        _userName = answer;
      }

      _updateThemeColor(answer);

      if (_currentQuestionIndex < _perguntas.length - 1) {
        _currentQuestionIndex++;
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _perguntas.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Widget _buildQuestion() {
    if (_currentQuestionIndex == 1 || _currentQuestionIndex == 9) {
      // Campo aberto
      return TextField(
        onSubmitted: _onAnswerSelected,
        decoration: InputDecoration(
          labelText: _perguntas[_currentQuestionIndex],
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (_opcoes[_currentQuestionIndex].isNotEmpty) {
      // Opções de resposta
      return Column(
        children: _opcoes[_currentQuestionIndex].map((option) {
          return ListTile(
            title: Text(option),
            onTap: () => _onAnswerSelected(option),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink(); // Nenhuma opção definida
  }

  // Geração de PDF
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Resumo das Respostas',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ..._perguntas.asMap().entries.map((entry) {
              int index = entry.key;
              String question = entry.value;
              String answer = _answers[index]?.toString() ?? "Não respondido";
              return pw.Text('$question: $answer');
            }).toList(),
          ],
        );
      },
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/resumo_respostas.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFScreen(filePath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeColor,
      appBar: AppBar(
        title: Text(
          _userName.isEmpty ? 'Colmeia Soluções' : 'Olá, $_userName.',
        ),
        backgroundColor: _themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentQuestionIndex < _perguntas.length
            ? SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _perguntas[_currentQuestionIndex],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildQuestion()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentQuestionIndex > 0)
                          ElevatedButton(
                            onPressed: _goToPreviousQuestion,
                            child: const Text('Anterior'),
                          ),
                        if (_currentQuestionIndex < _perguntas.length - 1)
                          ElevatedButton(
                            onPressed: _goToNextQuestion,
                            child: const Text('Próxima'),
                          ),
                      ],
                    ),
                    if (_currentQuestionIndex == _perguntas.length - 1)
                      ElevatedButton(
                        onPressed: _generatePdf,
                        child: const Text('Salvar em PDF'),
                      ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        ..._perguntas.asMap().entries.map((entry) {
                          int index = entry.key;
                          String question = entry.value;
                          String answer =
                              _answers[index]?.toString() ?? "Não respondido";
                          return ListTile(
                            title: Text('$question: $answer'),
                            onTap: () {
                              setState(() {
                                _currentQuestionIndex = index;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex =
                            0; // Voltar para a primeira pergunta
                      });
                    },
                    child: const Text('Editar Respostas'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class PDFScreen extends StatelessWidget {
  final String filePath;

  const PDFScreen({required this.filePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Resumo")),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
