## Usage

Firstly, configure the app template by changing the information in `./initialise/config.txt`. Then run the script as follows:

```
./create-node-app $APP_NAME $APP_DESCRIPTION`
```

Install the script globally (into `/usr/bin`) by running `./install.sh`; thereafter, it can be ran as follows:

```
create-node-app ...
```

#### Github

Call the following to create the Github repository (requires [hub](https://github.com/github/hub)):

```
hub create $APP_NAME
git push -u origin master
```

#### npm

Call the following to publish the npm apps with bumped versions:

```
npm run publish:patch
npm run publish:minor
npm run publish:major
```

Initial publish is achieved by calling `npm run publish:public`

