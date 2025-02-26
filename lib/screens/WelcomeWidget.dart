import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFbfdbfe), Color(0xFF93c5fd), Color(0xFF3b82f6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Menu and Logo
                        Row(
                          children: [
                            SizedBox(width: 8),
                            Row(
                              children: [
                                Image.asset('assets/logo.png', height: 30),
                                SizedBox(width: 8),
                                Text(
                                  'POS WALLA',
                                  style: GoogleFonts.getFont(
                                    'Poppins', // Use Poppins font
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Header Icons
                        Row(
                          children: [
                            InkWell(
                              onTap: () {},
                              child: Icon(Icons.favorite_border,
                                  color: Colors.black),
                            ),
                            SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Icon(Icons.person_outline,
                                  color: Colors.black),
                            ),
                            SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Icon(Icons.person_add_outlined,
                                  color: Colors.black),
                            ),
                            SizedBox(width: 16),
                            // make this icon navigate to admin login page
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/adminLogin');
                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.admin_panel_settings_outlined,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Left side content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.getFont(
                                'Poppins', // Use Poppins font
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(text: 'Where\n'),
                                TextSpan(
                                  text: 'Every ',
                                  style: TextStyle(color: Color(0xFFFFD700)),
                                ),
                                TextSpan(text: 'Sale\n'),
                                TextSpan(text: 'Meets\n'),
                                TextSpan(text: 'Success!'),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFD700),
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.023,
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.032,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'SIGN UP',
                                  style: GoogleFonts.getFont(
                                    'Poppins', // Use Poppins font
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.013,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.023,
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.032,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'LOGIN',
                                  style: GoogleFonts.getFont(
                                    'Poppins', // Use Poppins font
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.013,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Image positioned at the bottom-right corner
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/landingpage_image.png',
                  height: MediaQuery.of(context).size.height *
                      0.9, // 50% of screen height
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
