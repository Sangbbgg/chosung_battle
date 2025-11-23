import 'package:flutter/material.dart';
import '../game_core.dart';

class CardPickScreen extends StatefulWidget {
  final int pickCount;
  final void Function(List<CardType>) onSubmit;
  final bool isRandomMode;

  const CardPickScreen({
    Key? key,
    required this.pickCount,
    required this.onSubmit,
    this.isRandomMode = false,
  }) : super(key: key);

  @override
  State<CardPickScreen> createState() => _CardPickScreenState();
}

class _CardPickScreenState extends State<CardPickScreen> {
  List<CardType> picked = [];

  @override
  void initState() {
    super.initState();
    if (widget.isRandomMode) {
      _doRandomPick();
    }
  }

  void _doRandomPick() {
    List<CardType> pool = List.from(CardType.values);
    pool.shuffle();
    setState(() => picked = pool.take(widget.pickCount).toList());
  }

  void _togglePick(CardType t) {
    if (picked.contains(t)) {
      setState(() => picked.remove(t));
    } else {
      if (picked.length < widget.pickCount) setState(() => picked.add(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Text('카드 ${widget.pickCount}장 선택', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
            children: CardType.values.map((card) {
              bool sel = picked.contains(card);
              return GestureDetector(
                onTap: widget.isRandomMode ? null : () => _togglePick(card),
                child: Container(
                  width: 120, height: 78,
                  decoration: BoxDecoration(
                    color: sel ? Colors.orange : Colors.white,
                    border: Border.all(color: sel ? Colors.deepOrange : Colors.grey, width: 3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cardTypeTitle[card]!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: sel ? Colors.white : Colors.orange)),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(cardTypeDesc[card]!, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          if (!widget.isRandomMode)
            OutlinedButton(
              onPressed: _doRandomPick,
              child: const Text('랜덤 선택'),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: picked.length == widget.pickCount ? () => widget.onSubmit(picked) : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('선택 완료'),
          ),
        ],
      ),
    );
  }
}
