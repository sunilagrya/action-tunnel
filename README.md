# Action Tunnel

To run this locally

#### Server

`bundle exec ruby server_control.rb run`<br />
It will start your server in port **8080**<br />
Try this by
`curl localhost:8080`
#### Client

`ruby client.rb`<br />
 This will start your client<br />
```Established a connection with server..
Your URL is hello.localhost:8080
Your client to connected to port 3000
```
Now the client request has been established. You can try the below command to hit port 3000<br />
`curl hello.localhost:8080`

**Note:** In local this will work in Postman or curl. It won't work on browser because **subdomain** is not valid domain. You can add your local url to `/etc/hosts` it will work.

____
To run in production

You can create aws or digital ocean VPS

#### Server

`bundle exec ruby server_control.rb start`<br />
It will start your server in port **8080**<br />
Try this by
`curl SERVERIP:8080`

#### Nginx Config

_See **rubyapp.conf** file_

#### Client

Put your **SERVERIP** in client.rb and run the client file to connect to your server


