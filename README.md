Two-Way Traffic Light Controller with Pedestrian Request & Emergency Override

Overview

This project implements a digital traffic light control system for a two-way intersection (Side A and Side B) using Verilog. It features a robust Finite State Machine (FSM) that manages traffic flow, handles asynchronous pedestrian requests via latching logic, and includes a safety-critical emergency override system.

Key Features

Two-Way Traffic Control: Standard Green -> Yellow -> Red cycle for two intersecting roads.
Pedestrian "Scramble" Phase: Pedestrians have an exclusive phase (all cars Red) when a request button is pressed.
Emergency Override: A dedicated switch immediately turns all traffic lights Red to allow emergency vehicles to pass, while simultaneously resetting the internal state machine to a safe starting point.
Clock Division: Includes a parameterizable clock divider to convert high-speed system clocks (e.g., 50MHz) down to human-readable 1-second ticks.
Simulation Ready: The clock divider parameter allows for rapid simulation without waiting for millions of clock cycles.
