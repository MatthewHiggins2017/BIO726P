# **Improve & Refine Your Unix Skills**

---------------------------------------------

## **Goal**

Throughout this tutorial, you'll uncover **22 hidden characters**—each one a piece of a secret word. Tackle each challenge below to reveal the next character. Ready to sharpen your skills and solve the puzzle? Let the hunt begin!

---------------------------------------------

## Preparations

!!! Task

    Create a new directory `UNIX_Skills_Recap` and then copy the exercises directory `/shared/data/bash_tutorial/exercises` into `UNIX_Skills_Recap`

    ```
    mkdir UNIX_Skills_Recap
    cd ./UNIX_Skills_Recap
    cp -r /shared/data/bash_tutorial/exercises .
    ```

    The steps outlined below shall be completed in the `./UNIX_Skills_Recap` directory.

---------------------------------------------


## 1. **Directories and files**


### 1.1. Navigating directories

The **first character** is hidden in a file somewhere in the *exercise1*
directory tree. Use the commands

```
cd <directory_name>
```

(do not type the pointy brackets, just insert the directory name) and

```
ls
```

to move from one directory to the next. Look through subdirectories
until you find one with the name `solution_1.1` and list its contents.
If you went to a wrong directory, you can go back one level by typing:

```
cd ..
```

or go back to your home folder:

```
cd
```

### 1.2. Show a hidden file

Some files are not visible immediately. To see them, you need the
command

```
ls -a
```

The **second character**, is in the same directory as the first one, but
in a hidden file.

### 1.3. Execute a program

Use cd .. to go back to the directory `exercise_1/directoryB/`. When
listing its contents, you should see a **shell script file**
`program.sh`. To find the **third character**, you need to execute the
program. On bash, this is done by typing source and the name of the
program:

```
source program.sh
```

### 1.4. Find out how big a file is

Go to the folder `exercise_1/directoryC/`. To find **the fourth
character**, you need to find out how big the text file in the directory
is. This is done with the command

```
ls -l
```

In the table the command produces, you will find the file size in bytes,
the file’s owner, permissions to read and modify it, and the date/time
of the last modification.

To obtain the fourth character look up the file size in the [Table of
printable ASCII
characters](https://en.wikipedia.org/wiki/ASCII#Printable_characters):


----

## 2. Edit text files

Please use `cd ..` to go back to the top directory of the tutorial
material. Then, change to the directory `exercise_2`.

### 2.1. See what is in a text file

In the directory *exercise\_2/*, you will find a text file
*solution\_2.1.txt*. The **fifth character** is inside that file. To see
its contents, use the command

```
less <filename>
```

### 2.2. Edit text files

To get **character number six**, you will need to create a text file in
the `exercise_2` directory. On Ubuntu, you can do this using the editor
`nano`. You can start it typing the name of the program, or

```
nano <filename>
```

**To exit nano, type Ctrl-X**

Create a text file with the characters you have found so far.

The **sixth character** is the one you need to press to *write out* in
`nano`.


------------------------

## 3. Copy and remove files

Please go to the directory exercise\_3.

### 3.1. Create a directory and copy a file to it.

To find **characters seven and eight**, you need to create a
subdirectory named *solution* in `exercise_3/` and copy the files from
the `part1/` and `part2/` folders into it.

For creating directories, use the command:

```
mkdir <directory name>
```

For copying, you can use the command

```
cp <filename from> <filename to>
```

Type `ls -l solution/*` afterwards to see the solution.

### 3.2. Removing files

In the `data` directory, all files with an `Y` need to be deleted. To do
so, use the command:

```
rm <filename>
```

Also, there are more files to be deleted in the *data* directory. To
remove more than one file at once, you can use `*` as a wildcard, i.e.
`rm ju*` will delete all of `junk.txt, juniper.txt` and `june.docx`.

To get **characters nine and ten**, look at the files that remain after
deleting all that contain a `Y`.


----

## **4. Process text data**

Please go to the directory exercise\_4.

### 4.1. comparing two files

There are two different versions of a quote, `ai.txt`, and
`artificial_intelligence.txt`. To find out, how they differ, Unix
provides the command

``` 
diff <filename1> <filename2>
```

Of course, you can look at the text first using `less` or `nano`. The
**11th character** of the solution is the single character in which the
two files differ.

### 4.2. Sorting a text file

Unix has a small program to sort text files alphabetically. It is called
by

```
less <filename> | sort
```

The symbol '|' is called a pipe and is often used to connect Unix
programs to each other. The **12th character** of the solution is the
first character of the last word in the alphabetically sorted file
elephant.txt.


### 4.3. Finding words in a text file

To look for specific words in a text file, use the command

```
grep <word> <filename>
```

It produces all lines from the given file that contain the given word.
The `grep` command is very powerful and can handle Regular Expressions.

To find the **13th character**, search for the word **fire** in the file
`datascience.txt` and take the **first** character of the output.


----

## 5. Unzip files

Please go to the directory exercise\_5.

### 5.1. unzipping archives

Unzipping compressed files is a very basic and important task. On Unix,
you often encounter WinZip archives, .tar archives and .gz compressed
files. For unpacking Win zip files, use

```
unzip <filename>
```

for .tar and .tar.gz files

```
tar -xf <filename>
```

and for .gz files,

```
gunzip <filename>
```

The **14th and 15th character** of the solution are in a multiply
wrapped archive in the exercise\_5 directory.


----

## 6. Command-line tools

Please go to the directory `exercise_6`.

### 6.1. Changing file access rights

Each file on Unix has separate permissions for reading 'r', writing 'w',
and executing 'x'. Displaying them with:

```
ls -l
```

There is one triplet of permissions for the owner of the file owner, one
triplet for a group of users, and one for all others. The `chmod`
command allows to change these permissions, e.g.

```
chmod a+x <filename>
```

grants all users the permission to execute a file, while chmod u-w
forbids the current user (oneself) to write to the file (thereby
protecting it from being deleted accidentally).

To see **characters 16+17** of the solution, make the program
`permissions.sh` executable. Then execute it with:

```
./permissions.sh
```


### 6.2. How much disk space have I left?

To find out, how much disk space you have left, you can use the command

```
df
```

`df` lists all hard drive partitions, CD-ROMs, pendrives and some
logical partitions Unix uses. All numbers are given in kilobyte (1000
byte or one 1000000th GB).

To obtain the **18th character**, check out the version of the `df`
program. Find out how to do that with:

```
df --help
```

The solution is the last character of the first authors' first name.

### 6.3. Set an environment variable

To install some programs, it is necessary to set so-called environment
variables. These can be set using the command

``` 
export <variable-name>=<value>
```

You can see all variables by the command

```
env
```

To obtain the **19th character**, you need to use `export` to set the
variable *GIVEME* to the value **SOLUTION**.

```
echo $GIVEME
```

Find out the **characters position in the alphabet** with:

```
echo $GIVEME | wc -c
```


### 6.4. Using Git


Git is a distributed version control system that helps developers track changes in their code and collaborate efficiently. It allows multiple people to work on the same project simultaneously without overwriting each other's work.

The **20th character** is the first character of the git parameter which allow you to record changes to the repository. Use `git --help`

``` 
git --help
```

### 6.5. Managing processes

To see what programs are running on your machine, type

``` 
top
```

It displays you a list of all currently active programs. *Shift+P* sorts
them by the CPU time they are using, *Shift+M* by the amount of memory
they are using (if you don't see any program consuming lots of memory,
start a web browser). Quit `top` by pressing *q*.

The **last two characters** of the solution are the first two characters
of the second word in the line containing the column labels.


You find the pid number in the first column of the *top* output. Of
course, you may only interrupt your own programs, not those owned by
*root*, the system administrator.

----

### Acknowledgements

This tutorial was originally created by **Dr. Kristian Rother (© 2024)** and has been adapted by Matthew Higgins.
