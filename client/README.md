# Journey Planner - Commute Comparison Tool

A Flutter application designed to help commuters compare various travel options from locations in East Yorkshire (Beverley, Hull, Brough, York, Eastrington) to Wellington Place, Leeds.

## Features

- **Multi-modal Comparison:** Compare journeys using Train, Car, Bus, Cycle, and Uber.
- **Key Metrics:** Calculates and displays:
  - **Time:** Total journey duration including buffers.
  - **Cost:** Estimated travel cost.
  - **CO2 Emissions:** Environmental impact of the journey.
  - **Risk:** Assessment of potential delays or issues (e.g., weather dependence, connection risks).
- **Route Options:** Handles "First Mile" (Access), "Main Leg" (Train), and "Final Mile" (Egress) segments.

## Route Data

The application uses JSON data to define route options and calculate metrics. The logic handles complex scenarios like park & ride, transfers, and specific pricing models for different starting hubs.

## Design System

We maintain a comprehensive design system to ensure visual consistency and accessibility. This includes our color palette, typography choices, and spacing guidelines.

For a full write-up of our design decisions and style guide, please see [DESIGN.md](DESIGN.md).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
