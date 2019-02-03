# IOI in a Box

The purpose of the _IOI in a Box_ project is to develop a set of Docker containers containing ready-to-use instance of the Contest Management System (<http://cms-dev.github.io/>) configured with the tasks from the recent IOI's. The project, when completed, will make it possible for anyone to quickly and easily run an instance of an fully configured evaluation system and provide a simulation of the IOI experience.

## Installation

The project is tested on Ubuntu 16.04 x64 and Ubuntu 18.04 x64, but should work on any x64 Linux distribution where `docker` and `docker-compose` run and where the Linux kernel has support for control groups and namespaces.

### Prerequisites

- Install the `docker` engine and tools using the instructions for your system: <https://docs.docker.com/install/>.

- Add the current user to the `docker` group to make sure you can build and manage docker images as non-root user: <https://docs.docker.com/install/linux/linux-postinstall/>.

- Install the `docker-compose` tool using the instructions for your system: <https://docs.docker.com/compose/install/>

- Install the `wget` utility, python3 interpreter and the package to set up cgroups.

  ```
  sudo apt install python3 cgroup-lite wget
  ```

### Building the docker images

Run the install script. The script will

- Build the `ioi_box_cms` docker image containing a stable version of the Contest Management System.
- Download the `postgres` docker image containing an isolated postgres database engine.
- Create and initialize the CMS database.
- Start the system (database and CMS services)

The script has to download few hundred megabytes of data and it may take a while to finish.

```
./install.sh
```

## Running the Contest Management System

To start the database and CMS services use the `docker-compose` tool:

```
docker-compose up
```

To stop the services use the same tool.

```
docker-compose down
```

## Accessing the Contest Management System

CMS admin interface is available at <http://localhost:18889/>. After installation, first step should be to change the admin password at <http://localhost:18889/admin/1>. 

CMS contest interface is available at <http://localhost:18888/>. Installation script 

Dummy user is created during installation with username `user` and password `password`. Same user is added as a participant to every imported contest. You can manage users at <http://localhost:18889/users>.

## Importing a contest

Currently, we can only import zip-ed contest archives in the CMS `italy` format. In the next phase, we will write adapters for particular contests. 

To import a contest use the `importer.py` utility:
```
./importer.py contests/ioi2017_day1.py
```

The tool will download the zip file containing the contest data and add it to the contest database.

## Issues and troubleshooting

### Time limits

Current time limits are multipliers of original time limits that work on my machine. You'll need to adjust manually if needed. Utility to measure CPU performance and adjust the limits automatically when importing a contest is planned.

### CMS logs

Content Management System logs are stored inside a docker volume `ioi_box_cms_logs`. To find the actual file on your system inspect the volume and navigate to the specified mountpoint. You may need superuser privileges to access the log data.

```
docker inspect ioi_box_cms_logs
```

### Resetting the CMS database

If you want to reset the CMS database and start over, shutdown the services, delete the docker volumes storing the database and log data and run the install script again. _Warning_ all CMS data (tasks, contest, submissions) will be lost.

```
docker-compose down
docker volume rm ioi_box_cms_logs
docker volume rm ioi_box_pg_data
./install.sh
```

### Security considerations

Configuration assumes deployment on a single user machine. Use caution when making the service available to untrusted users. 
