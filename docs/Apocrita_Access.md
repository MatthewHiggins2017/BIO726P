# **Accessing Apocrita**

---------------------------------------------

* Apocrita is the high performance computing cluster (HPC) here at QMUL.
* You will use Apocrita in Week 2 of this module and also for your coursework.
* Full details on Apocrita can here found [here](https://docs.hpc.qmul.ac.uk). 
* Before you can use Apocrita you need to request an account and that is the goal for this practical session! 

 
-----------------------------------------------------

### **What is an SSH-Key Pair?**

To connect to Apocrita you will again be using SSH just like how you connected to your Virtual Machines (VMs). However, as Apocrita has a higher level of security you will need to use an SSH-Key Pair. 

An **SSH-Key Pair** consists of two cryptographic keys: a **public key** and a **private key**.

These keys are used to securely authenticate your identity when connecting to remote servers, such as Apocrita.

- The **public key** can be shared freely and is placed on the server you want to access.

- The **private key** is kept secure on your own computer and **should never be shared**.

When you attempt to connect to a server using SSH, the server checks if your public key matches your private key. If they match, you are granted access. This method is more secure than using passwords alone.

-----------------------------------------------------


### **Generating your SSH-Key Pair** 

Now its time to generate your own SSH-Key Pair!

Use the command below to achieve this but please remember to replace `<YOUR_QMUL_USERNAME>` with your actual QMUL username e.g. `bty313`:

```
# Template
ssh-keygen -t rsa -b 4096 -f ~/.ssh/Apocrita_Key_<YOUR_STUDENT_ID>
```

Example, if your QMUL username was *bty313*

```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/Apocrita_Key_bty313
```
This command will generate two files in your standard SSH directory (`~/.ssh/`):

* `Apocrita_Key_<YOUR_STUDENT_ID>` — your **private key** (keep this secure and never share it).
* `Apocrita_Key_<YOUR_STUDENT_ID>.pub` — your **public key**.

Always keep your private key confidential. Only the public key (.pub) should be shared when requested.


------------------------------------------

## Requesting an Apocrita Account

To allow the ITS Research Support Team to create your Apocrita account, please complete the following two steps:

1. **Verify your details:**  
    Visit the Excel table on OneDrive and check that your QMUL username and email address are correct: [**TABLE LINK HERE!**](https://qmulprod-my.sharepoint.com/:x:/r/personal/qp252136_qmul_ac_uk/Documents/BIO726P/BIO726P_Apocrita_Student_Accounts.xlsx?d=w6233a7bb4457425e8b479b9f52df788f&csf=1&web=1&e=P5bomv). If you spot any errors, contact a demonstrator or post in the Discussion Forum.
    
    <br>


2. **Upload your public SSH key:**  
    Upload your **public key** file `Apocrita_Key_<YOUR_STUDENT_ID>.pub` to this [shared OneDrive folder (**LINK HERE**)](https://qmulprod-my.sharepoint.com/:f:/r/personal/qp252136_qmul_ac_uk/Documents/BIO726P/BIO726P_Apocrita_Public_Keys?csf=1&web=1&e=uxsjSY). To make this easier, you can copy your public key from the SSH directory to your Desktop using the command below so it is easier to select to when uploading:  
    ```
    cp ~/.ssh/Apocrita_Key_<YOUR_STUDENT_ID>.pub ~/Desktop
    ```

<br>
Once you have completed these steps, ITS Research Support will email you within a few days to confirm your account has been created and instructions for how to log into **Apocrita**.

![Apocrita Email](./img/Apocrita_Email.png)

If you’d like to learn more about Apocrita before the session with ITS on October 2nd, please check out these resources:

1. [Apocrita Home](https://docs.hpc.qmul.ac.uk)
2. [HPC Introduction](https://docs.hpc.qmul.ac.uk/intro/)
3. [Logging Into Apocrita](https://docs.hpc.qmul.ac.uk/intro/login/)



