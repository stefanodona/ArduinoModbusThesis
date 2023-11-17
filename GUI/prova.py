import json

parameters = {
    "stat_creep_flag": 1,
    "loadcell_fullscale": 1,
    "min_pos": -10.0,
    "max_pos": 10.0,
    "num_pos": 0,
    "avg_flag": 0,
    "ar_flag": 0,
    "th1_val": 5.0,
    "th1_avg": 5,
    "th2_val": 12.0,
    "th2_avg": 3,
    "th3_val": 15.0,
    "th3_avg": 2,
    "vel_flag": 1,
    "vel_max": 50.0,
    "acc_max": 5,
    "time_flag": 0,
    "time_max": 0.5,
    "creep_displ": 10.0,
    "creep_period": 100.0,
    "creep_duration": 15.0,
}

my_json = json.dumps(parameters, indent=4)


# file = open("provajson.json", 'w')
# file.write(my_json)
# file.close()


file = open("provajson.json", 'r')
parameters2 = json.loads(file.read())
file.close()
print("p1: ",parameters)
print("p2: ",parameters2)

