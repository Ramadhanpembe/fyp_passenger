import 'package:flutter/material.dart';
import 'package:fyp_passenger/utils/constants.dart';

import '../utils/data.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Where to?',
              style: TextStyle(
                fontSize: 64,
                color: Color(0xff463f3a),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 4,
                // mainAxisSpacing: 20,
                // crossAxisSpacing: 10,
              ),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return GestureDetector(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                    color: const Color(0xffedede9),
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            routes[index].firstTerminal,
                            style: kTerminalStyle,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const CircleAvatar(
                            foregroundColor: Color(0xfff4f3ee),
                            backgroundColor: Color(0xffbcb8b1),
                            child: Icon(Icons.sync_alt),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            routes[index].lastTerminal,
                            style: kTerminalStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              itemCount: routes.length,
            ),
          ),
        ],
      ),
    );
  }
}
