import re
import pandas as pd


def parse(filepath):
    """
    Parse iwlist scan results

    Parameters
    ----------
    filepath : str
        Filepath for file to be parsed

    Returns
    -------
    data : pd.DataFrame
        Parsed data

    """
    data = []

    with open(filepath, 'r') as file:
        line = next(file)
        while line:
            str_line = line.strip()
            if(str_line.startswith("Cell")):
                dict_entry = {
                            'address': "",
                            'channel': "",
                            'frequency': "",
                            'quality': "",
                            'sLevel': "",
                            'essid': ""
                        }
                dict_entry["address"] = line.split(": ")[1].strip()
            if(str_line.startswith("Channel")):
                dict_entry["channel"] = line.split(":")[1].strip()
            
            if(str_line.startswith("Frequency")):
                reg_match = _RegExLib(str_line)
                dict_entry["frequency"] = reg_match.frequency.group(1)

            

            if(str_line.startswith("Extra: Last beacon")):
                data.append(dict_entry)
            
        

            line = next(file, None)

    return data

class _RegExLib:
    """Set up regular expressions"""
    _reg_frequency = re.compile('\d+\.\d+')
    _reg_grade = re.compile('Grade = (.*)\n')
    _reg_name_score = re.compile('(Name|Score)')

    def __init__(self, line):
        # check whether line has a positive match with all of the regular expressions
        self.frequency = self._reg_frequency.match(line)
        self.grade = self._reg_grade.match(line)
        self.name_score = self._reg_name_score.search(line)

if __name__ == '__main__':
    filepath = "/home/petrol/scripts/iwlist_parse/test.txt"
    data = parse(filepath)
    print(data)
