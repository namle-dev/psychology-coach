import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' as convert;

class ChatScreen extends ConsumerStatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> psychologyKeywords = [
    "cảm xúc", "stress", "lo âu", "trầm cảm", "động lực",
    "tâm lý", "tư vấn", "tự tin", "mất ngủ", "căng thẳng", "mối quan hệ"
  ];
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  bool isPsychologyRelated(String input) {
    return psychologyKeywords.any((keyword) => input.toLowerCase().contains(keyword));
  }

  Future<void> sendMessage() async {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userInput});
      _controller.clear();
      isLoading = true;
    });

    if (!isPsychologyRelated(userInput)) {
      setState(() {
        messages.add({"sender": "bot", "text": "🛑 Xin lỗi, tôi chỉ hỗ trợ các câu hỏi liên quan đến tâm lý."});
        isLoading = false;
      });
      return;
    }

    try {
      //OPEN AI
      // final response = await http.post(
      //   Uri.parse("https://api.openai.com/v1/chat/completions"),
      //   headers: {
      //     "Authorization": "Bearer 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",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode({
      //     "model": "gpt-3.5-turbo",
      //     "messages": [
      //       {"role": "system", "content": "Bạn là một chuyên gia tâm lý."},
      //       {"role": "user", "content": userInput}
      //     ],
      //   }),
      // );


      final response = await http.post(
        Uri.parse("https://api.forefront.ai/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer sk-SQcNX2v3InlwrNE1Qn2uzG2kzTJ7g5df", // Thay API Key tại đây
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "alpindale/Mistral-7B-v0.2-hf", // Thay bằng model do Forefront AI cung cấp
          "prompt": userInput,
          "temperature": 0.7,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        // String reply = jsonDecode(response.body)["choices"][0]["message"]["content"].trim();
        // setState(() {
        //   messages.add({"sender": "bot", "text": "🤖 AI: $reply"});
        // });

        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        String reply = decodedData["choices"][0]["message"]["content"].trim();

        setState(() {
          messages.add({"sender": "bot", "text": "🤖 AI: $reply"});
        });
      } else {
        print("⚠️ Lỗi API: ${response.body}"); // In lỗi ra console
        setState(() {
          messages.add({"sender": "bot", "text": "⚠️ Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau!"});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "bot", "text": "❌ Lỗi kết nối. Vui lòng kiểm tra mạng của bạn."});
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("💬 Chat với AI Tâm Lý")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isUser = message["sender"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi về tâm lý...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(), // Nhấn Enter để gửi
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
