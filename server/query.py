import re
from collections import OrderedDict
from copy import copy
import server.db_backend
import server.utils as utils

class Field:
    def __init__(self, name, validator=None, parser=None):
        self.name = name
        self.validator = validator
        self.parser = parser
        self.required = True

    def rename(self, name):
        new = copy(self)
        new.name = name
        return new

    def optional(self):
        new = copy(self)
        new.required = False
        return new

    def required(self):
        new = copy(self)
        new.required = True
        return new

def many_optional(fields, which_ones):
    new = []
    for f in fields:
        if f.name in which_ones:
            new.append(f.optional())
        else:
            new.append(f)
    return new

class Query:
    def __init__(self, query_string, param_fields, result_fields):
        """
        Args:
            query_string (str): The sql query to execute with %s as a param placeholder
            param_fields (List[Field]): A description of the parameters needed for the query
            result_fields (List[Field]): A description of the results from the query
        """
        self.query_string = query_string
        self.param_fields = param_fields
        self.result_fields = result_fields

    def get_params_template(self):
        """Creates a params template containing the keys of all params
        Returns:
            dict: The template
        """
        return {field.name: None for field in self.param_fields}

    def get_result_template(self):
        """Creates a params template containing the keys of all results
        Returns:
            dict: The template
        """
        return {field.name: None for field in self.result_fields}

    def get_required_param_names(self):
        """Returns the set of all param names which are required
        Returns:
            set: The required params
        """
        return set(field.name for field in self.param_fields if field.required)

    def build_params_tuple(self, params=None):
        """Validates the given params and returns a tuple of the values in the correct order for the query.

        Args:
            params (dict): A mapping between param name and value
        Returns:
            tuple: The params tuple to use with the query string
        """
        if params:
            defined_params = set(name for (name, value) in params.items() if value != None)
        else:
            defined_params = set()

        required_params = self.get_required_param_names()

        if not required_params.issubset(defined_params):
            missing = defined_params - required_params
            raise ValueError("Missing required params: {0}".format(missing))

        params_list = []

        for field in self.param_fields:
            if field.name not in params:
                params_list.append(None)
            else:
                value = params[field.name]
                if value != None and field.validator != None and not field.validator(value):
                    raise ValueError("Parameter failed validation: ({0}, {1})".format(field.name, value))
                params_list.append(value)

        return tuple(params_list)

    def load_result_tuple(self, result_tuple):
        """Loads the result of a query, parsing fields as needed

        Args:
            result_tuple (tuple): One row of output from the query
        Returns:
            dict: The result
        """
        if len(result_tuple) != len(self.result_fields):
            raise ValueError("Length of given tuple ({0}) does not match length of query result fields ({1})".format(
                             len(result_tuple), len(self.result_fields)))

        output = {}
        for (val, field) in zip(result_tuple, self.result_fields):
            parsed_val = val
            if val != None and field.parser != None:
                parsed_val = field.parser(val)
            output[field.name] = parsed_val

        return output

    def run(self, params=None):
        #utils.log("Running query with params", params)
        params_tuple = self.build_params_tuple(params)
        rows = server.db_backend.run_query(self.query_string, params_tuple)
        return [self.load_result_tuple(row) for row in rows]

def generic_get(table_name, key_column_names):
    template = """SELECT * FROM {0} WHERE {1};"""
    where_part = " AND ".join(["{0}=%s".format(name) for name in key_column_names])
    return template.format(table_name, where_part)

def generic_create_or_update(table_name, column_names):
    template = """INSERT INTO {0} ({1})
VALUES ({2})
ON DUPLICATE KEY UPDATE
{3};"""
    columns_part = ", ".join([name for name in column_names])
    params_part = ", ".join(["%s" for name in column_names])
    last_part = ",\n".join(["{0}=VALUES({0})".format(name) for name in column_names])
    return template.format(table_name, columns_part, params_part, last_part)
