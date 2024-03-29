#!/usr/bin/env python
# -*- coding: utf-8 -*-

from charts.amountsource import AmountSource
from matplotlib.ticker import AutoMinorLocator
from typing import Union
import calendar
import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.style as style
import numpy as np
import os
import pandas as pd
import pathlib
import time

max_categories_7days = 6  # max number of categories to show for 7 days plot
max_categories_progress = 5  # max number of categories to show for progress plot

plot_style = u'ggplot'
mpl.use('Agg')
style.use(plot_style)

def generate_charts(output_dir: pathlib.Path,
                    amount_source: AmountSource,
                    day: datetime.date,
                    output_timestamp: Union[str, None] = None,
                    only_monday_to_friday: bool = False):
    timestamp_outputpath = output_dir / 'timestamp'
    chart_7days_outputpath = output_dir / 'chart_7days.png'
    chart_progress_outputpath = output_dir / 'chart_progress.png'

# Generate timestamp if it is not given via command line arguments
    if output_timestamp is None:
        output_timestamp = str (time.time())

# Set the relevant weekdays.
    if only_monday_to_friday:
        relevant_weekdays = range(0, 5)
    else:
        relevant_weekdays = range(0, 7)

# Ensure output dir exists.
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

# Fetch from database.
    amount_categories = amount_source.categories()
    daily_goal = amount_source.daily_goal(day)
    amounts_last_31_days = amount_source.amounts_last_31_days(day)

# Find out relevant days in this month/week and compute monthly goal.
    relevant_days_this_month = sum(1 for x in range(calendar.monthrange(day.year, day.month)[1])\
        if datetime.date(day.year, day.month, x+1).weekday() in relevant_weekdays)
    relevant_days_this_month_until_today = sum(1 for x in range(day.day)\
        if datetime.date(day.year, day.month, x+1).weekday() in relevant_weekdays)

    relevant_days_this_week = len(relevant_weekdays)
    relevant_days_this_week_until_today = sum(1 for x in range(day.weekday() + 1) if x in relevant_weekdays)

    monthly_goal = daily_goal*relevant_days_this_month

# create index column with last 31 dates
    index = pd.date_range(start = day-datetime.timedelta(30), end = day)

# create dataframe containing aggregated amount (per category) per day for the last 31 days
    per_day = pd.DataFrame(index = index)
    number_of_categories = amount_categories.shape[0]
    for i in range(0,number_of_categories):
        category = amount_categories['category'][i]
        temp = amounts_last_31_days[amounts_last_31_days['category'] == category] # select appropriate category
        temp.drop('category', axis=1, inplace=True) # drop 'category' column (if dataframe is empty, taking the sum over the groupby object created next otherwise doesn't work)
        temp = temp.groupby(['date']).sum() # calculate sum over each date
        temp.columns = [category]
        per_day = per_day.join(temp)
    per_day = per_day.fillna(0)


### 7 days plot
# prepare for creating plot of last 7 days
    seven_days_per_day = per_day[-7:]

# create list of categories for 7 day plot
    seven_days_categories = seven_days_per_day.sum().sort_values(ascending=False)
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
    fig7days.savefig(chart_7days_outputpath)


### Make progress plots
    figprogress = plt.figure(figsize=(7,3))

### bar chart for this week's progress
# aggregate data
    this_week = per_day[-day.weekday()-1:].sum().sort_values(ascending=False)
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
    axweek.axvline(x=relevant_days_this_week_until_today*daily_goal, color='black', alpha=0.8, linewidth=2, zorder=1) # goal for this day of the week
    axweek.axvline(x=relevant_days_this_week*daily_goal, color='red', alpha=0.8, linewidth=2, zorder=1) # goal per week
# add minor ticks on the x-axis
    axweek.xaxis.set_minor_locator(AutoMinorLocator())
    axweek.grid(zorder=0, which='major', linewidth=0.8)
    axweek.grid(zorder=0, which='minor', linewidth=0.4)
    axweek.set_yticklabels([''])

### bar chart for this month's progress
# aggregate data
    this_month = per_day[-day.day:].sum().sort_values(ascending=False)
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
    axmonth.axvline(x=relevant_days_this_month_until_today*daily_goal, color='black', alpha=0.8, linewidth=2, zorder=1) # goal for this day of the month
    axmonth.axvline(x=monthly_goal, color='red', alpha=0.8, linewidth=2, zorder=1) # goal per month
# add minor ticks on the x-axis
    axmonth.xaxis.set_minor_locator(AutoMinorLocator())
    axmonth.grid(zorder=0, which='major', linewidth=0.8)
    axmonth.grid(zorder=0, which='minor', linewidth=0.4)
    axmonth.set_yticklabels([''])

### adjust legends and save figure
    figprogress.tight_layout()
    plt.setp(axweek.get_xticklabels(), visible=True) # otherwise the upper xtick labels will be unvisible...

    boxweek = axweek.get_position()
    axweek.set_position([boxweek.x0, boxweek.y0 + boxweek.height*0.5, boxweek.width, boxweek.height * 0.5])
    axweek.legend(fancybox=True, loc='lower center', prop={'size':10}, ncol=len(this_week.columns), bbox_to_anchor=(0.5,-1.6))

    boxmonth = axmonth.get_position()
    axmonth.set_position([boxmonth.x0, boxmonth.y0 + boxmonth.height*0.5, boxmonth.width, boxmonth.height * 0.5])
    axmonth.legend(fancybox=True, loc='lower center', prop={'size':10}, ncol=len(this_month.columns), bbox_to_anchor=(0.5,-1.6))

    figprogress.savefig(chart_progress_outputpath)

### save timestamp to file
    with open(timestamp_outputpath, 'w') as f:
        f.write(output_timestamp)
