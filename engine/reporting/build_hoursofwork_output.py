#!/usr/bin/env python
# -*- coding: utf-8 -*-

# absolute outputpaths regarding www_root as root (just like the server does)
summary_outputpath = '/generated_content/hoursofwork/summary.html'
chart_7days_outputpath = '/generated_content/hoursofwork/chart_7days.png'
chart_progress_outputpath = '/generated_content/hoursofwork/chart_progress.png'

max_categories_7days = 6  # max number of categories to show for 7 days plot
max_categories_progress = 5  # max number of categories to show for progress plot
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


# fetch from database
con = MySQLdb.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
# fetch hours to work in one week
weekly_goal = pd.io.sql.read_sql('select value from hoursofwork_goals where property="weekly goal"', con=con)['value'][0]
#fetch categories
db_categories = pd.io.sql.read_sql('select category from hoursofwork_categories order by priority', con=con)
#fetch data from last 30 days
db = pd.io.sql.read_sql("""
    select id, amount, date, category
    from hoursofwork
    where date >= date_sub(curdate(), interval 30 day)
    """, con=con, parse_dates=True, index_col="id")
con.close()


# find out date today and calculate daily goal
today = datetime.date.today()
daily_goal = weekly_goal/5.0
# find out businessdays in this month and calculate monthly goal
businessdays_this_month = sum( 1 for x in range( calendar.monthrange(today.year, today.month)[1] ) if datetime.date(today.year, today.month, 1+x).weekday() < 5)
businessdays_until_today = sum( 1 for x in range(today.day) if datetime.date(today.year, today.month, 1+x).weekday() < 5)
monthly_goal = daily_goal*businessdays_this_month


# create index column with last 31 dates
index = pd.date_range(start = today-datetime.timedelta(30), end = today)

# create dataframe containing hoursofwork (per category) per day for the last 31 days
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
ax7days.axhline(y=daily_goal, color='black', alpha=0.8, linewidth=2, zorder=1);
# add minor ticks on the y-axis
ax7days.yaxis.set_minor_locator(AutoMinorLocator())
ax7days.grid(zorder=0, which='major', linewidth=0.8)
ax7days.grid(zorder=0, which='minor', linewidth=0.4)
ax7days.set_xticklabels(formatted_xticklabels)
ax7days.legend(fancybox=True, loc='best', framealpha=0.8)
fig7days.tight_layout()
fig7days.savefig(config.www_root + chart_7days_outputpath)


### Make progress plots
figprogress = plt.figure(figsize=(7,3))

### bar chart for this week's progress
# aggregate data
this_week = per_day[-today.weekday()-1:].sum().order(ascending=False)
this_week = this_week[this_week != 0]
if len(this_week) == 0:
    this_week['Alles'] = 0
elif len(this_week) > max_categories_progress:
    this_week_small_entries = this_week[max_categories_progress-1:].sum()
    this_week = this_week[:max_categories_progress-1]
    this_week['Alles andere'] = this_week_small_entries
this_week = pd.DataFrame(this_week).transpose()

# plot data
axweek = figprogress.add_subplot(211)
this_week.plot(ax = axweek, kind='barh', stacked=True, title="Diese Woche", width=0.8, grid=False, zorder=2)
axweek.axvline(x=min((today.weekday()+1),5)*daily_goal, color='black', alpha=0.8, linewidth=2, zorder=1) # goal for this day of the week
axweek.axvline(x=5*daily_goal, color='red', alpha=0.8, linewidth=2, zorder=1) # goal per week
# add minor ticks on the x-axis
axweek.xaxis.set_minor_locator(AutoMinorLocator())
axweek.grid(zorder=0, which='major', linewidth=0.8)
axweek.grid(zorder=0, which='minor', linewidth=0.4)
axweek.set_yticklabels([''])

### bar chart for this month's progress
# aggregate data
this_month = per_day[-today.day:].sum().order(ascending=False)
this_month = this_month[this_month != 0]
if len(this_month) == 0:
    this_month['Alles'] = 0
elif len(this_month) > max_categories_progress:
    this_month_small_entries = this_month[max_categories_progress-1:].sum()
    this_month = this_month[:max_categories_progress-1]
    this_month['Alles andere'] = this_month_small_entries
this_month = pd.DataFrame(this_month).transpose()

# plot data
axmonth = figprogress.add_subplot(212)
this_month.plot(ax = axmonth, kind='barh', stacked=True, title="Diesen Monat", width=0.8, grid=False, zorder=2)
axmonth.axvline(x=businessdays_until_today*daily_goal, color='black', alpha=0.8, linewidth=2, zorder=1) # goal for this day of the month
axmonth.axvline(x=monthly_goal, color='red', alpha=0.8, linewidth=2, zorder=1) # goal per month
# add minor ticks on the x-axis
axmonth.xaxis.set_minor_locator(AutoMinorLocator())
axmonth.grid(zorder=0, which='major', linewidth=0.8)
axmonth.grid(zorder=0, which='minor', linewidth=0.4)
axmonth.set_yticklabels([''])

### adjust and save figure
figprogress.tight_layout()
plt.setp(axweek.get_xticklabels(), visible=True) # otherwise the upper xtick labels will be unvisible...

boxweek = axweek.get_position()
axweek.set_position([boxweek.x0, boxweek.y0 + boxweek.height*0.5, boxweek.width, boxweek.height * 0.5])
axweek.legend(fancybox=True, loc='lower center', prop={'size':10}, ncol=len(this_week.columns), bbox_to_anchor=(0.5,-1.6))

boxmonth = axmonth.get_position()
axmonth.set_position([boxmonth.x0, boxmonth.y0 + boxmonth.height*0.5, boxmonth.width, boxmonth.height * 0.5])
axmonth.legend(fancybox=True, loc='lower center', prop={'size':10}, ncol=len(this_month.columns), bbox_to_anchor=(0.5,-1.6))

figprogress.savefig(config.www_root + chart_progress_outputpath)


### create html files and save them
# the ? creates a query with a random string which is given by time.time()
#  to make sure the browser doesn't cache images even though new ones have been generated

output = u"""
<h1>Arbeitszeitenübersicht</h1>
<img src="{}?{!s}" alt="" />
<img src="{}?{!s}" alt="" />""".format(chart_7days_outputpath, time.time(), chart_progress_outputpath, time.time())


### write to file
f = open(config.www_root + summary_outputpath, 'w')
f.write(output.encode('utf-8'))
f.close