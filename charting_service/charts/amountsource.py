import calendar
import datetime
import pandas as pd
import pymysql
from abc import ABC, abstractmethod


class AmountSource(ABC):
    """
    Provides amounts from which charts can be generated.
    """

    @abstractmethod
    def daily_goal(self) -> float:
        '''
        Indicates the total amount the user aims for per day.
        '''
        pass

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
    def amounts_last_31_days(self) -> pd.DataFrame:
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
# TODO: per pandas docs, we should use a SQLAlchemy connectable instead of pymysql if we want to use 'read_sql'.
        self.con = con

    def daily_goal(self) -> float:
        return pd.read_sql('SELECT value FROM calories_goals WHERE property="daily goal"', con=self.con)['value'][0]

    def categories(self) -> pd.DataFrame:
# TODO: the ORDER BY clause is likely completely irrelevant
        return pd.read_sql('SELECT category FROM calories_categories ORDER BY priority', con=self.con)

    def amounts_last_31_days(self) -> pd.DataFrame:
        return pd.read_sql("""
            SELECT id, amount, date, category
            FROM calories_entries
            WHERE date >= date_sub(curdate(), interval 30 day)
            """, con=self.con, parse_dates=True, index_col="id")

class HoursOfWorkAmountSource(AmountSource):
    def __init__(self, con: pymysql.Connection) -> None:
# TODO: per pandas docs, we should use a SQLAlchemy connectable instead of pymysql if we want to use 'read_sql'.
        self.con = con

    def daily_goal(self) -> float:
        weekly_goal = pd.read_sql('SELECT value FROM hoursofwork_goals WHERE property="weekly goal"', con=self.con)['value'][0]
        return weekly_goal/5.0

    def categories(self) -> pd.DataFrame:
# TODO: the ORDER BY clause is likely completely irrelevant
        return pd.read_sql('SELECT category FROM hoursofwork_categories ORDER BY priority', con=self.con)

    def amounts_last_31_days(self) -> pd.DataFrame:
        return pd.read_sql("""
            SELECT id, amount, date, category
            FROM hoursofwork_entries
            WHERE date >= date_sub(curdate(), interval 30 day)
            """, con=self.con, parse_dates=True, index_col="id")

class SpendingsAmountSource(AmountSource):
    def __init__(self, con: pymysql.Connection) -> None:
# TODO: per pandas docs, we should use a SQLAlchemy connectable instead of pymysql if we want to use 'read_sql'.
        self.con = con

    def daily_goal(self) -> float:
        monthly_goal = pd.read_sql('SELECT value FROM spendings_goals WHERE property="monthly goal"', con=self.con)['value'][0]
        today = datetime.date.today()
        return monthly_goal/calendar.monthrange(today.year, today.month)[1]

    def categories(self) -> pd.DataFrame:
# TODO: the ORDER BY clause is likely completely irrelevant
        return pd.read_sql('SELECT category FROM spendings_categories ORDER BY priority', con=self.con)

    def amounts_last_31_days(self) -> pd.DataFrame:
        return pd.read_sql("""
            SELECT id, amount, date, category
            FROM spendings_entries
            WHERE date >= date_sub(curdate(), interval 30 day)
            """, con=self.con, parse_dates=True, index_col="id")
