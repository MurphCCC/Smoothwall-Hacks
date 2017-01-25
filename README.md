# Smoothwall-Hacks

* 1/25/17
Over the past few weeks, I have been looking into ways to automate user logins for our Smoothwall Proxy server, without user intervention.  I want to be able to keep track of users and groups on the proxy server without requiring people to constantly log in each time their IP address changes.  I have been thinking about this idea for a long time and this repo contains some scripts and things that I have come up with to make this work and to make it as automated and seamless as possible.

I am currently using two servers to make this work.  Though the SWG has the capability to serve pac files on its own, I am currently using another server to serve up the pac files.  I create a master pac file (proxy.pac) and then whenever I need to add a new user, I simply sym-link to proxy.pac using a name that can easily identify that user.

Once this is in place and the user's device is set to use this new pac file, I check the apache logs on the pac server to ensure that their device is in fact requesting the correct pac file.  Once I know that this is working, I am them able to monitor the Apache logs and extract each line where a pac file is being requested.  It looks something like this:

localhost:8999 55.55.55.102 - - [25/Jan/2017:09:34:43 -0500] "GET /johndoe.pac HTTP/1.1" 200 2864 "-" "mdmd/1.0 CFNetwork/808.1.4 Darwin/16.1.0"

Now what I need to do, is to extract the IP address and the /proxy.pac .  I then run these results through sed/awk to remove the .pac extension and I end up with just an IP address and a name like this:

55.55.55.102 johndoe

Once I extract this information I send it into a text file, we'll call this one johndoe.txt.  The path will be in the root of the web directory.

Now comes the interesting part.  How can we turn this information into an automatic login?  The simplest way that I can think of is to simply pipe this information into a curl request which gets sent to the login page.  This step must be done on the Smoothwall device.  The reason that it has to be done on the Smoothwall is because we are going to be spoofing the IP address of the request and this can only be done if the request is coming from localhost, otherwise this information will get stripped out and replaced with the actual address of the server that is forwarding the information.

Here is what a login request would look like using the information above:

<code>
curl --header "X-Forwarded-For: 55.55.55.102" -d "USERNAME=johndoe&PASSWORD=password&submit=Login" http://127.0.0.1/ilogin
</code>

Let's break this down so that we understand what is going on.  We are calling curl using the --header option.  This option allows us to modify the header of our request.  Pretty straightforward.  Because we are doing this on the localhost we can modify the X-Forwarded-For option to be whatever we like.  If we were sending this request to another server, then whatever information we put here would get stripped out and replaced with the forwarding servers address.

So we are sending a POST request to the login page on the local server and spoofing the IP address that the request is coming from.  We are using the same information for the pac file as we are for the username, just to make things a little easier.  The password can be whatever makes most sense.  Since the user will never actually log in themselves, it makes sense to use something easy here.  Also, for security reasons this password should not be something that the user would actually use for anything else since it would be pretty easy to hack.

So how do we put this altogether and automate everything?  Well I have a proof of concept that I am currently using.  It is a bit crude and requires a set of scripts to be created for each user.  I believe that this can all be rolled into one script, however I am not ready to roll that out just yet so here is what we have so far.

On the pac file server, a cronjob gets created that runs once a minute or so.  This cronjob checks the apache log, extracts the IP and username and puts it into a text file.

On the Smoothwall, a script gets created that pulls in the text file for the user and for each entry inserts the IP into the X-Forwarded-For entry.  We are populating the USERNAME= manually at the moment which is why a script needs to be created for each user.  Then a cronjob is created that runs this script once a minute.


Finally, here is the crontab entry that would go on the Webserver serving up the pac file:

<code>
*/5 * * * * cat /var/log/apache2/other_vhosts_access.log | grep sammy.pac | sed '/192.168.8.21/d' | awk '{print $2}' | sort | uniq > /var/www/sammy.txt
</code>