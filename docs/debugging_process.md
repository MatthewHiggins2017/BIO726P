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

### **Step 4. Ask Colleagues / Your Neighbour**

If you've tried the above steps and are still stuck, don't hesitate to ask for help from those around you:

* **Explain the problem**: Describe what you're trying to do, what command you ran, and what error message you received. Often, articulating the problem helps you understand it better.

* **Share your screen or terminal output**: Show your colleague the exact error message and the commands you've run. They may spot something you missed.

* **Compare approaches**: Your neighbour might be using a slightly different approach that works, or they may have already solved a similar problem.

**Remember**: Collaboration is a key part of bioinformatics work. Helping each other debug problems is a valuable learning experience for everyone involved!

-----------------------------------------------------

### **Step 5. Ask an LLM (Large Language Model)**

Modern AI tools like ChatGPT, Claude, or GitHub Copilot can be helpful for debugging, but use them wisely:

* **Provide context**: Share the error message, the command you ran, and relevant details about your environment.

* **Don't blindly follow suggestions**: LLMs can make mistakes or provide solutions that don't apply to your specific situation. Always try to understand *why* the solution works.

* **Verify the solution**: Test suggested fixes carefully and check that you understand each part of the command or code change.

* **Learn from the explanation**: Ask the LLM to explain why the error occurred and how the solution addresses it. This helps build your debugging skills.

**CAUTION**: While LLMs are powerful tools, they should complement—not replace—your understanding. Always critically evaluate AI-generated solutions and ensure they make sense for your specific problem.

-----------------------------------------------------