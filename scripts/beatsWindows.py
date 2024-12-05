high = [1053, 2270]
low = [1661, 2879]
bassB = [1661, 6536]
bassC = [4103, 8969]

total_duration = 60000
window_length = 500

def generate_beat_sequence(beat_timings, total_duration):
    first = beat_timings[0]  # First timestamp
    second = beat_timings[1]  # Second timestamp
    interval = second - first  # Interval between beats
    # Generate sequence starting from the first timestamp
    timestamps = []
    current_time = first
    while current_time < total_duration:
        timestamps.append(current_time)
        current_time += interval  # Use calculated interval for progression
    return timestamps

# Generate sequences for each baet
high_sequence = generate_beat_sequence(high, total_duration)
low_sequence = generate_beat_sequence(low, total_duration)
bassB_sequence = generate_beat_sequence(bassB, total_duration)
bassC_sequence = generate_beat_sequence(bassC, total_duration)

# Create the window with binary  (0001 for instruments played)
def create_window_map_binary_0001(total_duration, window_length, sequences):
    num_windows = total_duration // window_length
    window_map = []

    # For each window
    for i in range(num_windows):
        window_value = 0  # Start with no instruments played (b'0000000000000000')

        # Check which instruments are played 
        for instrument_index, sequence in enumerate(sequences):
            for timestamp in sequence:
                if i * window_length <= timestamp < (i + 1) * window_length:
                    # Set the corresponding bit for the instrument 
                    window_value |= (1 << (instrument_index * 4))  # Set bit 

        window_map.append(window_value)

    return window_map

# Combine all sequence
sequences = [high_sequence, low_sequence, bassB_sequence, bassC_sequence]
window_map_binary_0001 = create_window_map_binary_0001(total_duration, window_length, sequences)
simulation_output_binary_0001 = []

for i, value in enumerate(window_map_binary_0001):
    # Convert each window value to 16-bit
    binary_value = f"b'{value:016b}'"
    simulation_output_binary_0001.append(f"Window {i}: {binary_value}")

for line in simulation_output_binary_0001[:120]:
    print(line)