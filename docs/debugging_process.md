# **The Debugging Process**



When working with command-line tools it's common to run into issues / bugs. This guide provides a systematic approach to debugging common errors.

-----------------------------------------------------

### **Step 1. Switch on Your Virtual Machine** 

If you recieve the following error message: 

```
ssh: connect to host matt.genomicscourse.com port 22: Operation timed out
```

This indicates your **AWS Virtual Machine (VM)** is not yet switched on. 

**SOLUTION**: To access your **AWS Virtual Machine (VM)** you have to first have to switch it on via the website [switch.genomicscourse.com](https://switch.genomicscourse.com) and wait 2-5 minutes for your machine to boot up! 

-----------------------------------------------------

### **Step 2. Check you are connected to your VM**

When you are connected to your **AWS Virtual Machine (VM)** there may be times when your connection drops and you are logged out. This can be due to:

* Bad internet connection. 
* User inactivity.

How can you tell if you have become disconnected? You may see the following statement printed to your terminal:

```
Connection to matt.genomicscourse.com closed.
client_loop: send disconnect: Broken pipe
```

Also, it is important to check at the command-prompt (bottom of the terminal, where you type in your commands) your username should be the same as that provided by Vitaly and the host (after the @ symbol) should by an IP address.

```
matt@ip-172-31-38-337:~$ 

```


**SOLUTION**: If this happens, make sure to reconnect, via ssh to your AWS VM before continuing with the practical! 


------------------------------------------------------

### **Step 3. File Not Found**

Let's say you are trying to run the command below:

```
fastqc --nogroup --outdir . input/reads.pe1.fastq.gz
```

However, you get an error message saying the file cannot be found, doesn't exist, or couldn't be read:

```
Skipping 'input/reads.pe1.fastq.gz' which didn't exist, or couldn't be read
```

When a command fails like this, follow these systematic steps to debug the problem:

   * **Check your current directory**: Use `pwd` (print working directory) to confirm where you are in the file system. Ensure you're in the correct location to run the command.

   * **Verify the file exists**: Use `ls -l input/reads.pe1.fastq.gz` to check if the file exists at the specified path. If you get a `No such file or directory` error, the file path is incorrect. Use the `tree` command to locate where your files actually are.

   * **Check the file has content**: Use `ls -l` to check the file size. If the size is **0**, the file is empty, indicating a problem with a previous step. You can also use `zcat input/reads.pe1.fastq.gz | head` to preview the file contents.

**SOLUTION**: Once you've identified the issue using the steps above, you can:

- Navigate to the correct directory using `cd`
- Correct the file path in your command
- Check if previous steps in your workflow completed successfully

-----------------------------------------------------