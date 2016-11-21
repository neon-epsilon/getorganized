#!/usr/bin/env python
# -*- coding: utf-8 -*-

# absolute outputpaths regarding www_root as root (just like the server does)
summary_outputpath = '/generated/workout/summary.html'
chart_7days_outputpath = '/generated/workout/chart_7days.png'
# fitnessscore goals
weekly_goal_fitness = 300.0 # Fitnessstudio
weekly_goal_back = 400.0 # Dehnen, Home Workout
daily_goal_overall = 150.0

max_categories_7days = 6  # max number of categories to show for 7 days plot
plot_style = u'ggplot'

# import module ../config/config.py and turn www_root into string
import pathlib, sys
file_name = pathlib.Path.cwd() / pathlib.Path(__file__)
sys.path.append(str(file_name.parent.parent / 'config'))
import config
config.www_root = str(config.www_root)

# other imports
import MySQLdb
import pandas as pd
import time
import datetime
import calendar
import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.style as style
style.use(plot_style)
import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator


# find out date today and calculate daily goal
today = datetime.date.today()
daily_goal_fitness = weekly_goal_fitness/7.0
monthly_goal_fitness = daily_goal_fitness * calendar.monthrange(today.year, today.month)[1]
daily_goal_back = weekly_goal_back/7.0
monthly_goal_back = daily_goal_back * calendar.monthrange(today.year, today.month)[1]


# fetch database tables
con = MySQLdb.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
db_categories = pd.io.sql.read_sql('select category from workout_categories order by priority', con=con)
db = pd.io.sql.read_sql("""
    select w.id, w.amount * c.fitnessscore_multiplier as score, w.date, w.category
    from workout w
    left join workout_categories c
    on w.category = c.category
    where w.date >= date_sub(curdate(), interval 30 day)
    """, con=con, parse_dates=True, index_col="id")
con.close()


# create index column with last 31 dates
index = pd.date_range(start = today-datetime.timedelta(30), end = today)

# create dataframe containing workout (total and per category) per day for the last 31 days
per_day = pd.DataFrame(index = index)
number_of_categories = db_categories.shape[0]
for i in range(0,number_of_categories):
    category = db_categories['category'][i]
    temp = db[db['category'] == category] # select appropriate category
    temp.drop('category', axis=1, inplace=True) # drop 'category' column (if dataframe is empty, taking the sum over the groupby object created next otherwise doesn't work)
    temp = temp.groupby(['date']).sum() # calculate sum over each date
    temp.columns = [category]
    per_day = per_day.join(temp)
per_day = per_day.fillna(0)


### 7 days plot
# prepare for creating plot of last 7 days
seven_days_per_day = per_day[-7:]

# create list of categories for 7 day plot
seven_days_categories = seven_days_per_day.sum().order(ascending=False)
seven_days_categories_nonzero = list( seven_days_categories[seven_days_categories != 0].index )
if len(seven_days_categories_nonzero) == 0:
    seven_days_per_day['Alles'] = np.zeros(7)
    seven_days_per_day = seven_days_per_day[['Alles']]
elif len(seven_days_categories_nonzero) > max_categories_7days:
    seven_days_per_day['Alles andere'] = seven_days_per_day[ seven_days_categories_nonzero[max_categories_7days-1:] ].sum(axis=1)
    seven_days_per_day = seven_days_per_day[ seven_days_categories_nonzero[:max_categories_7days-1] + ['Alles andere'] ]
else:
    seven_days_per_day = seven_days_per_day[seven_days_categories_nonzero]

# figure and plot handles
fig7days = plt.figure(figsize=(7,5))
ax7days = fig7days.add_subplot(111)

# create output chart for 7 days
formatted_xticklabels = seven_days_per_day.index.map(lambda t: t.strftime('%a %b %-d'))
seven_days_per_day.plot(ax = ax7days, kind='bar', stacked=True, rot=0, title="Letzte 7 Tage", grid=False, zorder=2)
# add horizontal lines to indicate the daily goal
ax7days.axhline(y=daily_goal_overall, color='black', alpha=0.8, linewidth=2, zorder=1);
# add minor ticks on the y-axis
ax7days.yaxis.set_minor_locator(AutoMinorLocator())
ax7days.grid(zorder=0, which='major', linewidth=0.8)
ax7days.grid(zorder=0, which='minor', linewidth=0.4)
ax7days.set_xticklabels(formatted_xticklabels)
ax7days.legend(fancybox=True, loc='best', framealpha=0.8)
fig7days.tight_layout()
fig7days.savefig(config.www_root + chart_7days_outputpath)


### create html files and save them
# the ? creates a query with a random string which is given by time.time()
#  to make sure the browser doesn't cache images even though new ones have been generated

output = u"""
<h1>Trainingsübersicht</h1>
<img src="{}?{!s}" alt="" />""".format(chart_7days_outputpath, time.time())


### write to file
f = open(config.www_root + summary_outputpath, 'w')
f.write(output.encode('utf-8'))
f.close
