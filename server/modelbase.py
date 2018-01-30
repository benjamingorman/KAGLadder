import json
import types

class Field:
    def __init__(self, index, deserializer=str, validator=(lambda x: True)):
        self.index = index
        self.deserializer = deserializer
        self.validator = validator

class MetaModel(type):
    def __new__(mcs, classname, bases, dictionary):
        # Try and detect which attributes are the Model fields
        fields = {}
        for k, v in dictionary.items():
            if v.__class__ == Field:
                fields[k] = v

        # Since we're going to use _fields to hold all the fields, don't pollute the class
        # With the original field properties which will go unused
        for name in fields.keys():
            del dictionary[name]

        dictionary["_fields"] = fields
        return type.__new__(mcs, classname, bases, dictionary)

class Model(metaclass=MetaModel):
    def __init__(self):
        for (name, field) in self.__class__.get_fields().items():
            self.__dict__[name] = None

    def serialize(self):
        return json.dumps(self.__dict__)

    def validate(self):
        names_fields = self.__class__.get_fields()
        for name, value in self.__dict__.items():
            validator = names_fields[name].validator
            try:
                assert(validator(value))
            except Exception:
                return False
        return True

    @classmethod
    def get_fields(cls):
        return cls._fields

    @classmethod
    def from_dict(cls, the_dict):
        names_fields = cls.get_fields()
        names = set(names_fields.keys())
        covered_names = set()

        instance = cls()
        for key, value in the_dict.items():
            if key in names:
                field = names_fields[key]
                instance.__dict__[key] = field.deserializer(value)
                if not field.validator(value):
                    raise ValueError("field {0}, value {1}".format(key, value))
                covered_names.add(key)
        assert(names == covered_names)
        return instance

    @classmethod
    def from_row(cls, row):
        names_fields = cls.get_fields()
        the_dict = {}
        for (name, field) in names_fields.items():
            the_dict[name] = row[field.index]
        return cls.from_dict(the_dict)

