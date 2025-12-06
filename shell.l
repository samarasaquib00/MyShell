/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */


%x incl
%{

#include <cstring>
#include "y.tab.hh"
#include "shell.hh"
#include <fstream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include "command.hh"
#include "shell.hh"
#include <unistd.h>
#include <iostream>
#include<string>



////////////  Start added code ///////////


extern "C" char * read_line();

int mygetc(FILE * f) {
  static char *p;
  char ch;

     if (!isatty(0)) {
  // stdin is not a tty. Call real getc
    return getc(f);
  }

  // stdin is a tty. Call our read_line.
  if (p==NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;
}

#undef getc
#define getc(f) mygetc(f)

/////////// End added code ///////////



static  void yyunput (int c,char *buf_ptr  );


void myunputc(int c) {
  unput(c);
}

bool Shell::_isSrc = false;
%}

%option noyywrap

%%




\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

"<" {
  return LESS;
}

">&" {
 return GREATAMPERSAND;
}

">>&" {
  return GREATGREATAMPERSAND;
}

"2>" {
  return TWOGREAT;
}

"&" {
  return AMPERSAND;
}

">>" {
  return GREATGREAT;
}

"|" {
  return PIPE;
}



\$\{\_\} {
  // HANDLE UNDERSCORE EXPANSION
  //printf("0\n");
  std::string s = std::string(yytext);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    std::string arg_str = Shell::_lastArg;
    final_string += arg_str;

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;

  //printf("final string: %s\n", final_string);

  yylval.cpp_string = new std::string(final_string);

  return WORD;
}


\$\{SHELL\} {

  // HANDLE SHELL EXPANSION
  std::string s = std::string(yytext);

  //printf("string: %s\n", s);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    // get the environment variable
    char var[128] = {0};
    realpath(Shell::_path, var);
    final_string += std::string(var);

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;


  yylval.cpp_string = new std::string(final_string);

  return WORD;

}







[^ \n\t]*\$\{[^ \t\n}!$?_][^ \t\n!?$}_]*\}[^ \t\n]* {
  // Environmental Variable Expansion

  std::string s = std::string(yytext);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    // get the environment variable
    // std::environ = s.substr(found_start_index + 2, environ_length)
    std::string environ = s.substr(found_start_index + 2, environ_length);


    //  final_string += get_env(environ)
    final_string += getenv(environ.c_str());

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;


  yylval.cpp_string = new std::string(final_string);

  return WORD;
}

\$\{\$\} {
  // HANDLE DOLLAR SIGN EXPANSION
  std::string s = std::string(yytext);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    // get the environment variable
    std::string environ = s.substr(found_start_index + 2, environ_length);


    //  final_string += pid
    int pid = getpid();
    std::string p_str = std::to_string(pid);
    final_string += p_str;

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;


  yylval.cpp_string = new std::string(final_string);

  return WORD;

}


\$\{\!\} {
  // HANDLE ! EXPANSION
  std::string s = std::string(yytext);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    // get the environment variable
    std::string code_str = std::to_string(Shell::_lastPid);
    final_string += code_str;

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;


  yylval.cpp_string = new std::string(final_string);

  return WORD;

}


\$\{\?\} {
  // HANDLE QUESTION EXPANSION
  std::string s = std::string(yytext);
  std::string final_string = "";   // append everything to this

  // find the first occurrence of "${", set that to found_start_index
  int found_start_index = s.find("${");

  while (found_start_index >= 0) {
    // s[found_start_index+2] = the starting index of the environment variable

    // closing_bracket_index = s.find("}")    this is the index of the end of the environment variable
    int closing_bracket_index = s.find("}");

    // int environ_length = closing_bracket_index - found_start_index - 2
    int environ_length = closing_bracket_index - found_start_index - 2;

    // create the string
    //    final_string += s.substr(0, found_start_index)
    final_string += s.substr(0, found_start_index);

    // get the environment variable
    std::string code_str = std::to_string(Shell::_returnCode);
    final_string += code_str;

    // Reset the string to delete the part that has already been handles - check the next part
    //  to see if there are more environment variables
    s = s.substr(closing_bracket_index+1);

    // Find the next occurrence of "${"
    found_start_index = s.find("${");

  }

  // Add any leftover string chars that need to be appended to the final_string
  final_string += s;


  yylval.cpp_string = new std::string(final_string);

  return WORD;

}



\$\([^ \t\n]*[^\t\n]*\) {
  /* SUBSHELL */

  // 1. A command containing a subshell command is passed to the shell
  // 2. The shell parses the echo command normally.
  // 3. The shell parses the subshell command `ls`
  // 4. After executing the command in the subshell the input is injected at the head of the buffer
  // 5. Finally the shell parses file1, file2, file3, and “and more” as the arguments to echo.

  // Implement this feature by:

  // Scanning the command between backticks in shell.l


  // Reading the output from the child process and putting the characters of the output back into the scanner’s
    // buffer using the function yy_unput(int c) in reverse order. See the FAQ for more details.
  yytext[strlen(yytext) - 1] = '\0';              // deletes the last parentheses - replaces with null terminator
  std::string *s = new std::string(&yytext[2]);   // deletes the dollar sign at the beginning

  // Preprocessing
  std::string exit = "exit\n";


  // Calling your own shell as a child process and passing it the command as input.
    // You will need two pipes to communicate with the child process; one to pass the command to the child,
    // and the other to read the output from the child.

  // send the command as an input to the shell

  // Set up Inputs
  int tmpin = dup(0);

  // Set up Outputs
  int tmpout = dup(1);

  // Set up Pipes
  int pin[2];
  int pout[2];

  pipe(pin);
  pipe(pout);

  write(pin[1], s->c_str(), s->size());   //subshell input
  write(pin[1], "\n", 1);               //adding a newline
  write(pin[1], exit.c_str(), exit.size());
  //write(pin[1], "\n", 1);               //adding a newline
  close(pin[1]);

  // before execute, reset stdin and stdout to point to the pipe
  dup2(pin[0],0);   // redirecting pin to stdin
  dup2(pout[1],1);     // redirecting pout to standard output

  close(pin[0]);
  close(pout[1]);

  int ret = fork();

  if (ret == 0) {
    execvp("/proc/self/exe", NULL);
    perror("execvp");
    _exit(1);
  } else if (ret < 0) {
    perror("fork");
    _exit(1);

  }

  waitpid(ret, NULL, 0);
  dup2(tmpout, 1);
  dup2(tmpin, 0);
  close(tmpout);
  close(tmpin);

  int i = 0;
  std::string buffer;
  char x;
  //build the string by reading through pout[0]
  while(read(pout[0], &x, 1)) {
    // check if it's a newline
    if (x == '\n') {
      buffer += ' ';
    } else {    // any other character
      buffer+= x;
    }
    i++;
  }
  //buffer += '\0';     // null terminator
  buffer = buffer.c_str();

  // reverse the buffer string
  // go the index of the last character in the string, BUT delete the "Exiting Shell" that prints
  int j = buffer.size() - strlen("Exiting Shell  ");
  while (j >= 0) {
    myunputc(buffer[j]);
    j--;
  }
}


"source "[^ \t\n|><]+ {

    /* Create a string for the file name */
    std::string *file_name = new std::string(yytext + strlen("source "));
    /* Use the ifstream library to create a file pointer */
    std::ifstream file;
    /* Open the file */
    file.open(*file_name);

    /* Create an arraylist (vector) of strings called listofcommands */
    /* Each line in the file is its own command */
    std::vector<std::string> list_of_commands;

    /* Variable to keep track of a certain command (line in the file) */
    std::string command;

  /* Iterate through the file and append '\n' to each command/line */
   while(std::getline(file, command)) {
        command += "\n";

        /* Use pushback to insert/PUSH the command into the list_of_commands. It pushes to the end */
        list_of_commands.push_back(command);
    }

    /* Close the file */
    file.close();

    /* Reverse the list because push_back appends backwards */
    for(int i = list_of_commands.size() - 1; i >= 0; i--) {
    /* For each command, go char by char and call myunputc() on the char */
        for (int j = list_of_commands[i].length() - 1; j >= 0; j--) {
            myunputc(list_of_commands[i][j]);
        }
   }

// create a string for the file name
// if stream library -- allows you to create a file pointer
  // after you open the file, create an arraylist(vector) of strings called listofcommands
      //while you iterate through the file (use std::getline()), append(pushback) current command in our file to + \n
      //close file when done
    //reverse list because pushback appends backwards
    //iterate through list of commands, and output them using myunputc. for each command, go char by char and call myunputc()
                                                                          // iterate through the current command in reverse order
}




<<EOF>> {
  yypop_buffer_state();
  if (!YY_CURRENT_BUFFER) {
    yyterminate();
  }
}


~[^ \n\t|<>]* {
  std::string s = std::string(yytext);
  std::string home = getenv("HOME");
  if (s.size() == 1) {
    yylval.cpp_string = new std::string(home);
  }
  else {
    if (s[1] == '/') {
      s = home + s.substr(1);
    }
    else {
      s = std::string("/homes/") + s.substr(1);
    }
    yylval.cpp_string = new std::string(s);
  }
  return WORD;
}


[^ \t\n|><&\\][^ \t\n|><&\\]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}




["][^\n\"]*["] {
  std::string s = std::string(yytext);
  s = s.substr(1, s.length() - 2);
  yylval.cpp_string = new std::string(s);
  return WORD;
}

[^ \t\n|><&]*\\[^ \t\n]* {
  std::string s = std::string(yytext);
  // iterate through the string and delete each backslash
  int i = 0;
  while (s[i] != '\0') {
    if (s.at(i) == '\\') {
      s.erase(i, 1);
    }
    i++;
  }
  yylval.cpp_string = new std::string(s);
  return WORD;
}



