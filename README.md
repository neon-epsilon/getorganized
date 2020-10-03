Welcome to GetOrganized, a simple dashboard and tracker for your expenses, diet, working hours and for managing your shoppinglist.

A working demo can be found here: [getorganizeddemo.ddns.net/](http://getorganizeddemo.ddns.net/)

# Purpose

I built this tool for my personal use because similar apps didn't do exactly what I wanted and I would need several apps for budgeting, calorie counting, etc. With GetOrganized, I have everything in one place. Additionally, I have direct access to my data and can analyze it e.g. in a Jupyter notebook or via SQL queries.

Moreover, I use this project to learn about the different parts of web development and to try out interesting new technologies. To get a good idea of how everything works, I wrote everything myself from the bottom up with minimal use of frameworks - this is not just another Bootstrap app ;)

# What does it do?

At its core GetOrganized is a CRUD application: it allows you to enter and delete your expenses, consumed calories, etc. After entering or deleting an expense, the charts get updated, showing your expenses for the last 7 days and last month. To keep your budget in check, one can set a monthly goal for the expenses. (The goal is currently set by editing a corresponding database entry.)

The generated charts look like this:
![picture](http://getorganizeddemo.ddns.net/generated/spendings/chart_7days.png)
![picture](http://getorganizeddemo.ddns.net/generated/spendings/chart_progress.png)
The black lines in the charts represent the goal for the current day, the red lines the goal for the week and month, respectively. In the horizontal bar charts, the black line progresses every day until it meets the red line at the end of the week/month. (In the case of working hours, the black lines do not progress on Saturday and Sunday.)

# Tech

I host GetOrganized on a Raspberry Pi running [NGINX](https://www.nginx.com/). The front end is written in the purely functional language [PureScript](https://www.purescript.org/), a non-lazy Haskell dialect which compiles directly to JavaScript. The front end communicates with the server via a REST API, written in PHP. Upon entering or deleting an expense, calorie count, etc. the API starts a Python script which updates the charts. The Python script is based on [pandas](https://pandas.pydata.org/).

### Front End

The front end is built according to [The Elm Architecture](https://guide.elm-lang.org/architecture/), which later inspired Redux. Instead of Elm, however, I used [purescript-pux](https://github.com/alexmingoia/purescript-pux), as PureScript is far more flexible and powerful. Pux renders the web page using [Preact](https://preactjs.com/), a lightweight alternative to React.

In accordance to The Elm Architecture/Redux, the entire state of the web page is stored in a single object. How the page is rendered depends only on this global state object. Whenever an event, like a mouse click, is triggered, this event together with the current state is used to compute the new state of the app, or to trigger another event.

Side effects can only be executed via events. This makes this architecture robust and easy to maintain. Additionally, PureScript's excellent compiler and type system make it difficult to introduce bugs that result in runtime errors, and refactoring or introducing new features is a breeze.

### Design

The style sheets for GetOrganized were written entirely from scratch (except the use of normalize.css) as an educational project to get a feeling for the capabilities of CSS. The design is responsive, i.e. works both on desktop and mobile, and does not utilize JavaScript to achieve this. The drop down menu in the mobile version is also written entirely in CSS by making use of (invisible) checkboxes.

### Back End

The REST API is written in plain PHP: as it basically only performs CRUD tasks, I went with something simple. POST and DELETE requests (e.g. when adding or deleting a calorie count) trigger a Python script that updates the corresponding charts with the help of pandas.

In the future, I plan to replace the simple Python scripts by a micro service running on a Python server like Tornado. This should speed up the process of updating charts significantly. Currently, a Python script is started for each POST or DELETE request, which means that pandas, numpy and several other libraries are imported every time. This is quite slow and even more so on the Raspberry Pi 3 which currently hosts my instance of GetOrganized. Running a Tornado server that takes care of updating the charts would mean that these libraries are only imported when the server is started.
