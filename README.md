# 🥭prodmango
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**prodmango** is an AI-driven productivity tool designed to bridge the gap between your long term ambitions and your daily schedule. 

By connecting to OpenRouter, prodmango takes your big life goals and the amount of free time you have today, and dynamically generates a personalised, to do list. Instead of feeling overwhelmed by massive goals, prodmango gives you small, actionable steps to help you make incremental progress every single day.



## Features

*   **AI Powered Task Generation:** Uses the OpenRouter API to intelligently break down abstract goals into concrete, actionable steps.
*   **Time Aware Planning:** Input how much free time you have today, and prodmango will generate tasks that perfectly fit your schedule (e.g., 30m, 1h blocks).
*   **Ambition Tracking:** Every generated task is tagged with its parent ambition (e.g., "gain 10 kg muscle" or "learn to skateboard") to keep you motivated and remind you *why* you are doing the work.
*   **Distraction Free UI:** A sleek, dark mode interface featuring three simple tabs: 
    *   **Focus:** Your daily generated action plan.
    *   **Mango:** Where you define your long-term ambitions.
    *   **Settings:** Configuration and API key management.

## Getting Started

### Prerequisites

*   To build and run this project, you will need:
*   A Mac running macOS.
*   [Xcode](https://developer.apple.com/xcode/) (Latest version recommended).
*   An [OpenRouter API Key](https://openrouter.ai/) to power the AI task generation.

### Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/LeonConway/prodmango.git](https://github.com/LeonConway/prodmango.git)
   ```
2. Navigate into the project directory:
   ```bash
   cd prodmango
   ```
3. Open the project in Xcode. (Double-click the prodmango.xcodeproj file).

4. Select My Mac as the run destination in the top Xcode toolbar.

5. Press Cmd + R (or click the Play button) to build and run.
Note: Because this is a Menu Bar app, you won't see a main window pop up in the center of your screen. Instead, look for the new icon in your top right menu bar!

## Usage

1. **Connect the AI:** Open the app, navigate to the **Settings** (gear icon) tab, and paste your OpenRouter API key.
2. **Set Your Ambitions:** Go to the **Mango** tab and input your high-level goals (e.g., "Learn to code", "Read more books", "Cook healthier meals").
3. **Generate Your Day:** Go to the **Focus** tab, input how much free time you have today, and click **✨ Generate Plan**.
4. **Take Action:** Check off your time boxed tasks as you complete them! 

## Tech Stack

* Language: Swift
* Platform: macOS
*   **AI Integration:** OpenRouter API

## Contributing

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.
