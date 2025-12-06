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
 * CS252: Systems Programming
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MAX_BUFFER_LINE 2048

extern void tty_raw_mode(void);

// Buffer where line is stored
int line_length;
char line_buffer[MAX_BUFFER_LINE];
int cursor;

// Simple history array
// This history does not change. 
// Yours have to be updated.
int history_index = 0;
char * history [100];
int history_size = 0;
int history_length = sizeof(history)/sizeof(char *);
int history_reverse = 0;      // change up arrow and down arrow

void read_line_print_usage()
{
  char * usage = "\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {

  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  cursor = 0;


  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32) {
      // It is a printable character.

      // INSERT
      if (cursor < line_length) {
        //insert in the beginning/middle
        //update the line buffer
        for (int i = line_length; i> cursor; i--) {
          line_buffer[i] = line_buffer[i-1];
        }
        line_buffer[cursor] = ch;     // update with the inserted character
        line_length++;                // update line length
        //update the visual terminal
        for (int i = cursor; i < line_length; i++) {
          ch = line_buffer[i];
          write(1, &ch, 1);
        }


        // MOVE THE CURSOR BACK
        for (int i = line_length; i > cursor + 1; i--) {
          ch = 8;
          write(1, &ch, 1);
        }

        // increment cursor
        cursor++;

      } else {


      // Do echo
      write(1,&ch,1);

      // If max number of character reached return.
      if (line_length==MAX_BUFFER_LINE-2) break; 

      // add char to buffer.
      line_buffer[line_length]=ch;
      line_length++;
      cursor++;
      }
    }
    else if (ch==1) {
      /* CTRL+A */
      while (cursor != 0) {
        cursor--;
        ch = 8;
        write(1,&ch,1);
      }

    }
    else if (ch == 5) {
      /* CTRL+E */
      while (cursor != line_length) {
        ch = line_buffer[cursor];
        cursor++;
        write(1, &ch, 1);
      }
    }
    else if (ch==10) {
      //printf("enter was typed\n");
      // <Enter> was typed. Return line
      // Print newline

      write(1,&ch,1);

      break;








    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    }
    else if (ch == 4) {
      // DELETE --> CTRL + D

      if (cursor == line_length) {
        continue;
      }

      if (line_length == 0) {
        continue;
      }


      // Go forward one character
      for (int i = cursor; i < line_length - 1; i++) {
        ch = line_buffer[i+1];
        line_buffer[i] = ch;
        write(1, &ch, 1);
      }

      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // for loop to bring cursor back
      for (int i = 0; i < line_length - cursor; i++) {
        ch=8;
        write(1,&ch,1);
      }

      // Remove one character from buffer
      line_length--;
    }
    else if (ch == 8 || ch==127) {
      /* BACKSPACE */
      // <backspace> was typed. Remove previous character read.

      if (line_length <= 0 || cursor <= 0) {
        continue;
      }


      // Replace all the characters to the right of cursor. Move everything to the left by 1
        for (int i = cursor; i < line_length; i++) {
          line_buffer[i-1] = line_buffer[i];
        }

      // Null terminate the line buffer to get rid of the extra space
      line_buffer[line_length-1] = '\0';

      // Go back to the cursor and delete everything
      ch = 8;
      for (int i = 0; i < cursor; i++) {
        write(1, &ch, 1);
      }

      // Write spaces in every spot after the cursor to overwrite the characters
      ch = ' ';
      for (int i = 0; i<line_length; i++) {
        write(1, &ch, 1);
      }

      // Go back to the appropriate spot
      ch = 8;
      for (int i = 0; i < line_length; i++) {
        write(1, &ch, 1);
      }

      // Write the letters that are in the line buffer that was updated to fill the command line
      for (int i = 0; i < line_length; i++) {
        write(1, &line_buffer[i], 1);
      }

      /* Bring the cursor back to the appropriate spot */
      for (int i = 0; i < line_length - cursor; i++) {
        write(1, &ch, 1);
      }

/*
      // Go back one character
      ch = 8;
      write(1,&ch,1);

      // for loop
      for (int i = cursor - 1; i < line_length; i++) {
        // read the chars to the right
        ch=line_buffer[i+1];
        line_buffer[i] = ch;
        write(1,&ch,1);
      }

      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // for loop to bring cursor back
      for (int i = 0; i < line_length - cursor + 1; i++) {
        ch=8;
        write(1,&ch,1);
      }
*/
      // Remove one character from buffer
      line_length--;
      cursor--;
      }
    //}
    else if (ch==27) {
      // Escape sequence. Read two chars more
      //
      // HINT: Use the program "keyboard-example" to
      // see the ascii code for the different chars typed.
      //
      char ch1;
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);

      // LEFT ARROW
      if (ch1==91 && ch2==68) {
        //if (line_length == 0) {
        //  continue;
        //}

        if (cursor > 0) {
        ch=8;

        write(1, &ch, 1);
        //line_length--;
        cursor--;
        }
      }
      // RIGHT ARROW
      if (ch1==91 && ch2==67) {
        //if (cursor > line_length) {
        //  continue;
        //}
        if (cursor < line_length && cursor >= 0 ) {
        ch = line_buffer[cursor];
        write(1, "\033[1C", 5);
        //line_length++;
        cursor++;
        }
      }


    if (ch1==91 && ch2==65) {
      history_reverse++;
      // Up arrow. Print next line in history.
      // Erase old line
      if (history_index > 0) {
      // make sure cursor is at the end of the line;

      // Print backspaces

      int i = 0;
      for (i =0; i < line_length; i++) {
        ch = 8;
        write(1,&ch,1);
      } // end for

      // Print spaces on top
      for (i =0; i < line_length; i++) {
        ch = ' ';
        write(1,&ch,1);
      } // end for

      // Print backspaces
      for (i =0; i < line_length/* + cursor */; i++) {
        ch = 8;
        write(1,&ch,1);
      } // end for

      // Copy line from history
      history_index--;
      if(history_index >= 0){
        strcpy(line_buffer, history[history_index]);
        line_length = strlen(line_buffer);
       }

      line_length = strlen(line_buffer);
      // echo line
      write(1, line_buffer, line_length);
      cursor = line_length;
      } // end if history index > 0
      } // end if up

    if (ch1==91 && ch2==66) {
      history_reverse--;
      if (history_reverse <= 0) {
        strcpy(line_buffer,"");
      }
    // DOWN ARROW
      // decrement history_reverse
      if (history_index > 0) {
      int i = 0;
      for (i =0; i < line_length; i++) {
        ch = 8;
        write(1,&ch,1);
      } // end for

      // Print spaces on top
      for (i =0; i < line_length; i++) {
        ch = ' ';
        write(1,&ch,1);
      } // end for

      // Print backspaces
      for (i =0; i < line_length /* + cursor */; i++) {
        ch = 8;
        write(1,&ch,1);
      } // end for

      // Copy line from history
      history_index++;
      if(history_index >= 0){
        strcpy(line_buffer, history[history_index]);
        line_length = strlen(line_buffer);
       }

      line_length = strlen(line_buffer);
      // echo line
      write(1, line_buffer, line_length);
      cursor = line_length;

      } // end if history index > 0
    } // end if down
    }

  } //end while



  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]='\0';

  history[history_index] = (char *)malloc(strlen(line_buffer)*sizeof(char)+1);

  if (line_length > 0) {

    strcpy(history[history_index], line_buffer);
    history_index++;
  }

  line_length = strlen(line_buffer);

  //printf("hist: %s\n", history[history_index-1]);

  return line_buffer;
}

