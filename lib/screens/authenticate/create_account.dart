// Import Flutter Library
import 'package:flutter/material.dart';


// Making a StatefulWidget representing the Create Account page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

// Create an instance of the state for the CreateAccountPage
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

// Making a State class for the CreateAccountPage
class _CreateAccountPageState extends State<CreateAccountPage> {
  
// Boolean to switch password visibility, init as true  
  bool hidePassword = true;

// Initializing strings to hold all of the user inputs
  String clientIDString = '';
  String emailString = '';

// Initializing this one with a / instead so the createAccountPasswordString doesnt equal confirmcreateAccountPasswordString off the bat
  String createAccountPasswordString = '/';
  String confirmcreateAccountPasswordString = '';

/*

  To make the Password security indicator we make an integer to 
  represent the how secure the password is based on the 4 conditions.

  When one of the conditions are met, the integer increases by one.

*/  

// Initializing an integer to represent the password security level
  int passwordSecurityIndicator = 0;
  
// Making a custom method to update the password security indicator based on the conditions
  void updatePasswordSecurityIndicator() {

// Making an internal int within the mehtod to track the number of conditions met
  int conditionsMet = 0;

  // Condition 1: Check if the length of createAccountPasswordString is greater than 8 characters
  if (createAccountPasswordString.length > 8) {
    conditionsMet++;
  }

  // Condition 2: Check if createAccountPasswordString contains at least one digit
  if (createAccountPasswordString.contains(RegExp(r'\d'))) {
    conditionsMet++;
  }

  // Condition 3: Check if createAccountPasswordString contains at least one uppercase letter
  if (createAccountPasswordString.contains(RegExp(r'[A-Z]'))) {
    conditionsMet++;
  }

  // Condition 4: Check if createAccountPasswordString contains at least one lowercase letter
  if (createAccountPasswordString.contains(RegExp(r'[a-z]'))) {
    conditionsMet++;
  }

  // Update passwordSecurityIndicator based on the number of conditions met
    if (conditionsMet == 0) {
      // None of the conditions are met, so the security of the password is 0
      passwordSecurityIndicator = 0;
    } else if (conditionsMet == 1) {
      // One condition met, so the security of the password is 1
      passwordSecurityIndicator = 1;
    } else if (conditionsMet == 2) {
      // Two conditions met, so the security of the password is 2
      passwordSecurityIndicator = 2;
    } else if (conditionsMet == 3) {
      // Three conditions met, so the security of the password is 3
      passwordSecurityIndicator = 3;
    } else if (conditionsMet == 4) {
      // All conditions met, so the security of the password is 4
      passwordSecurityIndicator = 4;
    }

  }

// Making a method to update the password string whenever the input changes to call it later in an easier way
  void updatecreateAccountPasswordString(String value) {
    setState(() {
      createAccountPasswordString = value;
    });
  }

// Making a method to call the 2 methods at once for the password field since the onChanged event will only support one
// This method will update the password string whenever the input changes and update the security indicator at the same time
    void updateFields(String value) {
      updatecreateAccountPasswordString(value);
      updatePasswordSecurityIndicator();
    }

// Making a build method for creating the UI
  @override
  Widget build(BuildContext context) {

// Wrapping everything in the scaffold widget to hold all the components
    return Scaffold(
      
// Adding a padding around the main content
      body: Padding(
        padding: const EdgeInsets.all(16.0),

// Wrapping everything in a SingleChildScrollView to make the screen scrollable
        child: SingleChildScrollView(

// Wrapping everything in a column to arrange children vertically
          child: Column(

// Centering the children
            mainAxisAlignment: MainAxisAlignment.center,

// Making a list of child widgets in the Column
            children: <Widget>[
              
// Adding some space here
              const SizedBox(height: 40.0),

// Adding an align widget to put the text "AGQ" at the top left of the screen
              const Align(
                alignment: Alignment.centerLeft,

// Text widget to display "AGQ"                
                child: Text(
                  "AGQ",
                  
// TextStyle to define text appearance
                  style: TextStyle(
                    fontSize: 40, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Titillium Web', 
                  ),
                ),
              ),

// Adding some space here
              const SizedBox(height: 60.0),

// Text widget to display "Create An Account"                
              const Text(
                "Create An Account",

// TextStyle to define text appearance
                style: TextStyle(
                  fontSize: 26, 
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Titillium Web'
                ),
              ),

// Adding some space here
              const SizedBox(height: 25.0),

// Container to hold the client ID text box with its own title
              Container(
                
// Adding some padding for this text box
                padding: const EdgeInsets.all(4.0),

// Making a column to arrange the client ID text box with its title vertically
                child: Column(

// Stretching the client ID text box with its title to fill the column to give the text box width
                  crossAxisAlignment: CrossAxisAlignment.stretch,

// Defining the children (client ID text box with its title) 
                  children: [

// Text widget to display "Client ID"                
                    const Text(
                      "Client ID",
                      
// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                        ),
                    ),

// Adding some space here
                    const SizedBox(height: 10.0),                    

// TextField widget for the user to Enter their client ID
                    TextField(

// TextStyle to define text appearance of the users input
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ), 

// InputDecoration for styling the input field
                      decoration: InputDecoration(
                                
// Placeholder text to display 'Enter your client ID'
                        hintText: 'Enter your client ID', 

// Styling the placeholder text
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122), 
                          fontFamily: 'Titillium Web'
                        ),

// Styling the border for the input field and giving it a rounded look
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),

// Changing the color of the border when the user interacts with it
                        focusedBorder: 
                          OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)), // Border color
                          ),

// Adding some padding so the input is spaced proportionally                         
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), // Padding for input content
                      ),

// Update the clientIDString with the new value inputted from the user
                        onChanged: (value) {
                          setState(() {
                            clientIDString = value;
                          });
                        },

// Closing the properties for the textfield
                    ),
                  ],
                ),
              ),
                            
// Adding some space here
              const SizedBox(height: 16.0),
          
// Container to hold the Email text box with its own title
              Container(

// Adding some padding for this text box
                padding: const EdgeInsets.all(4.0),

// Making a column to arrange the email text box with its title vertically
                child: Column(

// Stretching the email text box with its title to fill the column to give the text box width
                  crossAxisAlignment: CrossAxisAlignment.stretch,

// Defining the children (email text box with its title) 
                  children: [

// Text widget to display "Email"                
                    const Text(
                      "Email",
                      
// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ),
                    ),

// Adding some space here
                    const SizedBox(height: 10.0),                    

// TextField widget for the user to Enter their email
                    TextField(

// TextStyle to define text appearance of the user's input
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ), 

// InputDecoration for styling the input field
                      decoration: InputDecoration(

// Placeholder text to display 'Enter your email'
                        hintText: 'Enter your email', 

// Styling the placeholder text
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(255, 122, 122, 122), 
                            fontFamily: 'Titillium Web'
                          ),

// Styling the border for the input field and giving it a rounded look
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),

// Changing the color of the border when the user interacts with it
                        focusedBorder: 
                          OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                          ),

// Adding some padding so the input is spaced proportionally                         
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), // Padding for input content
                      ),

// Update the emailString when the value inputted from the user
                      onChanged: (value){
                        setState(() {
                          emailString = value;
                        });
                      },

// Closing the properties for the textfield
                    ),
                  ],
                ),
              ),
                        
// Adding some space here
              const SizedBox(height: 16.0),

// Container to hold the Password text box with its own title
              Container(

// Adding some padding for this text box
                padding: const EdgeInsets.all(4.0),

// Making a column to arrange the password text box with its title vertically
                child: Column(

// Stretching the password text box with its title to fill the column to give the text box width
                  crossAxisAlignment: CrossAxisAlignment.stretch,

// Defining the children (password text box with its title)
                  children: [

// Text widget to display "Password"
                    const Text(
                      "Password",
                      
// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ),
                    ),

// Adding some space here
                    const SizedBox(height: 10.0),

// TextField widget for the user to create a password
                    TextField(

// TextStyle to define text appearance of the user's input
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ), 

// InputDecoration for styling the input field
                      decoration: InputDecoration(

// Placeholder text to display 'Create a password'
                        hintText: 'Create a password', 

// Styling the placeholder text
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122), 
                          fontFamily: 'Titillium Web'
                        ),

// Styling the border for the input field and giving it a rounded look
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),

// Changing the color of the border when the user interacts with it
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),

// Adding some padding so the input is spaced proportionally                         
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),

// Adding an eye icon to toggle password visibility
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },

// Adding some padding for the icon
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),

// Icon widget to toggle password visibility
                            child: Icon(
                              
// Conditionally choosing between outlined and rounded eye icon based on password visibility
                              hidePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,

// Styling the eye icon
                              size: 25,
                              color: const Color.fromARGB(255, 154, 154, 154),

// Closing the eye Icon properties
                            ),
                          ),
                        ),
                      ),

//Making the Password visible depending on if the user pressed the icon 
                      obscureText: hidePassword,
                      
// Updating the password field and the password security indicator
                      onChanged: updateFields,

// Closing the Password Field properties
                    ),
                  ],
                ),
              ),

// Adding some space here
              const SizedBox(height: 12.0),

// Making a row of rounded rectangles for the password security indicator
            Row(

// Splitting the rectangles in different parts by assigning them as children
              children: [

// Making the first 3 rectangles in the row
                Row(
                    children:
                    List.generate(
                      3,

// Styling the rectangles
                      (index) => Container(

// Setting the width and height for the rectangles
                        width: 31, 
                        height: 5.5,

// Making a margin between rectangles
                        margin: const EdgeInsets.symmetric(horizontal: 4.4),

// Making conditional statements to change the color of the rectangles based on the security of the password
                        decoration: BoxDecoration(
                          color: passwordSecurityIndicator == 1
                          ? const Color.fromARGB(255, 149, 28, 28) // Red color for low security
                          : (passwordSecurityIndicator == 2 || passwordSecurityIndicator == 3)
                            ? const Color.fromARGB(255, 219, 195, 60) // Yellow color for medium security
                            : (passwordSecurityIndicator == 4)
                              ? const Color.fromARGB(255, 47, 134, 47) // Green color for high security
                              : const Color.fromARGB(255, 100, 116, 139), // Default color

// Applying a border radius to give the rectangles a rounded look
                          borderRadius: BorderRadius.circular(10.0),

// Closing properties for the first 3 rectangles in the row
                        ),
                      ),
                    ),
                  ),

// Making the next 2 rectangles in the row
                Row(
                  children: List.generate(
                    2,

// Creating a rectangle with specific dimensions and styling
                    (index) => Container(

// Adjust the width and height of each rectangle
                      width: 31,
                      height: 5.5,

// Adding some spacing between the rectangles
                      margin: const EdgeInsets.symmetric(horizontal: 4.4),

// Styling the rectangle based on the password security indicator
                      decoration: BoxDecoration(
                        color: passwordSecurityIndicator == 1
                          ? const Color.fromARGB(255, 100, 116, 139) // Default color for low security
                          : (passwordSecurityIndicator == 2 || passwordSecurityIndicator == 3)
                            ? const Color.fromARGB(255, 219, 195, 60) // Yellow color for medium security
                            : (passwordSecurityIndicator == 4)
                              ? const Color.fromARGB(255, 47, 134, 47) // Green color for high security
                              : const Color.fromARGB(255, 100, 116, 139), // Default color

// Applying a border radius to give the rectangle rounded corners
                        borderRadius: BorderRadius.circular(10.0),

// Closing properties for the next 2 rectangles in the row
                      ),
                    ),
                  ),
                ),         

// Making the next 2 rectangles in the row
                Row(
                  children: List.generate(
                    2,

// Creating a rectangle with specific dimensions and styling
                    (index) => Container(

// Adjust the width and height of each rectangle
                      width: 31,
                      height: 5.5,

// Adjust the horizontal spacing between rectangles
                      margin: const EdgeInsets.symmetric(horizontal: 4.4),

// Changing the color of the rectangles based on the password security indicator
                      decoration: BoxDecoration(
                        color: (passwordSecurityIndicator == 1 || passwordSecurityIndicator == 2)
                          ? const Color.fromARGB(255, 100, 116, 139) // Default color for low to medium security
                          : (passwordSecurityIndicator == 3)
                            ? const Color.fromARGB(255, 219, 195, 60) // Yellow color for medium-high security
                            : (passwordSecurityIndicator == 4)
                              ? const Color.fromARGB(255, 47, 134, 47) // Green color for high security
                              : const Color.fromARGB(255, 100, 116, 139), // Default color

// Applying a border radius to give the rectangle rounded corners
                        borderRadius: BorderRadius.circular(10.0),

// Closing Properties for the rectangles
                      ),
                    ),
                  ),
                ),

// Making the last 3 rectangles in the row
                Row(
                    children: 
                    List.generate(
                      3,

// Styling the rectangles
                      (index) => Container(

// Setting the width and height for the rectangles
                        width: 31, 
                        height: 5.5,

// Making a margin between rectangles         
                        margin: const EdgeInsets.symmetric(horizontal: 4.4), // Adjust the horizontal spacing

// Making conditional statements to change the color of the rectangles based on the security of the password
                        decoration: BoxDecoration(
                          color: (passwordSecurityIndicator == 1 || passwordSecurityIndicator == 2 || passwordSecurityIndicator == 3)
                          ? const Color.fromARGB(255, 100, 116, 139)
                          : (passwordSecurityIndicator == 4)
                              ? const Color.fromARGB(255, 47, 134, 47)
                              : const Color.fromARGB(255, 100, 116, 139),

// Applying a border radius to give the rectangles a rounded look
                          borderRadius: BorderRadius.circular(10.0), // Adjust the border radius for rounded corners

// Closing properties for the last 3 rectangles in the row
                        ),
                      ),
                    ),
                  ),

// Closing the row of rounded rectangles for the password security indicator
              ],
            ),
          
// Adding some space here
              const SizedBox(height: 20.0),
          
// Making a container to display password 8 character validation status
              Container(

// Adding some padding to the icon and text
                padding: const EdgeInsets.all(4.0), 

// Making a row holding the icon and text indicating password length validation
                child: Row(
                  children: [

// Making a conditional statement that changes the icon to a green checkmark when the passwword is at least 8 characters
                    createAccountPasswordString.length > 8
                        ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) 
                        : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), 

// Adding some space here
                    const SizedBox(width: 10.0),

// Text widget to display 'At least 8 characters'
                    const Text(
                      'At least 8 characters',

// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.white, 
                        fontFamily: 'Titillium Web'
                      ),
// Closing properties for the password length validation status
                    ),
                  ],
                ),
              ),

// Adding some space here
              const SizedBox(height: 16.0),

// Container for displaying whether the password contains at least one digit
              Container(

// Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

// Row holding the icon and text indicating the presence of at least one digit in the password
                child: Row(
                  children: [

// Conditional statement to change the icon to a green checkmark when the password contains at least one digit
                    createAccountPasswordString.contains(RegExp(r'\d'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

// Adding some space here
                    const SizedBox(width: 10.0),

// Text widget to display '1 digit'
                    const Text(
                      '1 digit',

// TextStyle to define text appearance
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                    ),

// Closing properties for the 1 digit condition display
                  ],
                ),
              ),
                
// Adding some space here
              const SizedBox(height: 16.0),

// Container for displaying whether the password contains at least one uppercase character
              Container(

// Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

// Row holding the icon and text indicating the presence of at least one uppercase character in the password
                child: Row(
                  children: [

// Conditional statement to change the icon to a green checkmark when the password contains at least one uppercase character
                    createAccountPasswordString.contains(RegExp(r'[A-Z]'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

// Adding some space here
                    const SizedBox(width: 10.0),

// Text widget to display '1 uppercase character'
                    const Text(
                      '1 uppercase character',

// TextStyle to define text appearance
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                    ),
                    
// Closing properties for the uppercase character condition display
                  ],
                ),
              ),

// Adding some space here
              const SizedBox(height: 16.0),
          
// Container for displaying whether the password contains at least one lowercase character
              Container(

// Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

// Row holding the icon and text indicating the presence of at least one lowercase character in the password
                child: Row(
                  children: [

// Conditional statement to change the icon to a green checkmark when the password contains at least one lowercase character
                    createAccountPasswordString.contains(RegExp(r'[a-z]'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

// Adding some space here
                    const SizedBox(width: 10.0),

// Text widget to display '1 lowercase character'
                    const Text(
                      '1 lowercase character',

// TextStyle to define text appearance
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                    ),
// Closing properties for the lowercase character condition display
                  ],
                ),
              ),
          
// Adding some space here
              const SizedBox(height: 16.0),
          
// Container for the confirmation password section
              Container(
                padding: const EdgeInsets.all(4.0), // Adjust padding as needed

// Column to arrange child widgets vertically
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

// Text widget for displaying "Confirm Password"
                    Text(
                      "Confirm Password",

// TextStyle conditionally set based on password security indicator
                      style: passwordSecurityIndicator == 4
                          ? const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web') // Style for valid condition
                          : const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'), // Style for invalid condition
                    ),
                    
// Adding some space here
                    const SizedBox(height: 10.0),

// TextField widget for entering and confirming the password
                    TextField(
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),

// InputDecoration for customizing the appearance of the text field
                      decoration: InputDecoration(

// Hint text to guide the user for entering the password
                        hintText: 'Enter your password',

// TextStyle for the hint text
                        hintStyle: const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'),

// Border styling for the text field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),

// Styling for the border when the text field is focused
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),

// Padding inside the text field content area
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      ),

// Hide entered text 
                      obscureText: true, 

// onChanged callback to update the confirmation password string
                      onChanged: (value) {
                        setState(() {
                          confirmcreateAccountPasswordString = value;
                        });
                      },

// Enable the text field based on the password security indicator
                      enabled: passwordSecurityIndicator == 4,

// Closing properties for the Confirm Password textfield
                    ),
                  ],
                ),
              ),
                        
// Adding some space here
              const SizedBox(height: 16.0),

// Making a "Next" button
              GestureDetector(

// Execute onTap logic only if the passwords match                
                onTap: createAccountPasswordString == confirmcreateAccountPasswordString
                  ? () {
                      Navigator.pushNamed(context, '/dashboard');                    
                    }
                  : null,

// Container holding the "Next" button
                child: Container(
                  height: 50,

// Decoration based on password match status
                  decoration: BoxDecoration(
                    color: createAccountPasswordString == confirmcreateAccountPasswordString
                        ? const Color.fromARGB(255, 30, 75, 137) // Color when passwords match
                        : const Color.fromARGB(255, 85, 86, 87),  // Color when passwords don't match
                    borderRadius: BorderRadius.circular(25),
                  ),

// Row to contain "Next" text and arrow icon
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next",

// TextStyle to define text appearance
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Titillium Web'
                        ),
                      ),

// Adding some space here
                      SizedBox(width: 10),

// Adding a white arrow
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),

// Closing properties for the Next button
                    ],
                  ),
                ),
              ),

// Adding some space here
              const SizedBox(height: 30.0),

// Row widget containing text and a GestureDetector for navigation to the login screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,

// Children widgets within the row
                children: [

// Text widget indicating the presence of an existing account
                  const Text(
                    'Already have an account?',

// TextStyle to define text appearance
                    style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),

// GestureDetector for handling taps on the "Login" text
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,

// onTap navigation to the login screen
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },

// TextButton widget styled as a link for navigating to the login screen
                    child: const TextButton(
                      onPressed: null, // Set onPressed to null or add your logic inside the GestureDetector
                      child: Text(
                        "Login",

// TextStyle to define text appearance
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.blue, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Titillium Web'
                        ),

// Closing the Message properties
                      ),
                    ),
                  ),
                ],
              ),

// Adding some space here
              const SizedBox(height: 20.0),


// Close all properties
            ],
          ),
        ),
      ),
    );
  }
}
