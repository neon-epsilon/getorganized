import calendar
import pandas as pd
import pymysql
from datetime import date
from abc import ABC, abstractmethod


class AmountSource(ABC):
    """
    Provides amounts from which charts can be generated.
    """

    @abstractmethod
    def categories(self) -> pd.DataFrame:
        '''
        Contains all the categories that the amounts can be part of.

        Invariants
        ----------
            Has column 'category' of type 'str'.
        '''
        pass

    @abstractmethod
    def daily_goal(self, day: date) -> float:
        '''
        Indicates the total amount the user aims for per day.
        '''
        pass

    @abstractmethod
    def amounts_last_31_days(self, day: date) -> pd.DataFrame:
        '''
        Contains all the amounts for the last 31 days (including the current day).

        Invariants
        ----------
            Has columns 'amount' ('float'), 'category' ('str') and 'date' ('datetime')

            The 'category' column only contains categories that are also returned
            from the 'categories' method.
        '''
        pass

class CaloriesAmountSource(AmountSource):
    def __init__(self, con: pymysql.Connection) -> None:
        # TODO: per pandas docs, we should use a SQLAlchemy connectable instead
        # of pymysql if we want to use 'read_sql'. Also applies to the other
        # `AmountSource` implementations here.
        self.con = con

    def categories(self) -> pd.DataFrame:
        # The ORDER BY only fixes the ordering.
        return pd.read_sql('SELECT category FROM calories_categories ORDER BY priority', con=self.con)

    def daily_goal(self, day: date) -> float:
        return pd.read_sql('SELECT value FROM calories_goals WHERE property="daily goal"', con=self.con)['value'][0]

    def amounts_last_31_days(self, day: date) -> pd.DataFrame:
        date_string = day.isoformat()

        return pd.read_sql(f"""
            SELECT id, amount, date, category
            FROM calories_entries
            WHERE date BETWEEN date_sub('{date_string}', interval 30 day) AND date_add('{date_string}', interval 1 day)
            """, con=self.con, parse_dates=True, index_col="id")

class HoursOfWorkAmountSource(AmountSource):
    def __init__(self, con: pymysql.Connection) -> None:
        self.con = con

    def categories(self) -> pd.DataFrame:
        # The ORDER BY only fixes the ordering.
        return pd.read_sql('SELECT category FROM hoursofwork_categories ORDER BY priority', con=self.con)

    def daily_goal(self, day: date) -> float:
        weekly_goal = pd.read_sql('SELECT value FROM hoursofwork_goals WHERE property="weekly goal"', con=self.con)['value'][0]
        return weekly_goal/5.0

    def amounts_last_31_days(self, day: date) -> pd.DataFrame:
        date_string = day.isoformat()

        return pd.read_sql(f"""
            SELECT id, amount, date, category
            FROM hoursofwork_entries
            WHERE date BETWEEN date_sub('{date_string}', interval 30 day) AND date_add('{date_string}', interval 1 day)
            """, con=self.con, parse_dates=True, index_col="id")

class SpendingsAmountSource(AmountSource):
    def __init__(self, con: pymysql.Connection) -> None:
        self.con = con

    def categories(self) -> pd.DataFrame:
        # The ORDER BY only fixes the ordering.
        return pd.read_sql('SELECT category FROM spendings_categories ORDER BY priority', con=self.con)

    def daily_goal(self, day: date) -> float:
        monthly_goal = pd.read_sql('SELECT value FROM spendings_goals WHERE property="monthly goal"', con=self.con)['value'][0]
        return monthly_goal/calendar.monthrange(day.year, day.month)[1]

    def amounts_last_31_days(self, day: date) -> pd.DataFrame:
        date_string = day.isoformat()

        return pd.read_sql(f"""
            SELECT id, amount, date, category
            FROM spendings_entries
            WHERE date BETWEEN date_sub('{date_string}', interval 30 day) AND date_add('{date_string}', interval 1 day)
            """, con=self.con, parse_dates=True, index_col="id")
