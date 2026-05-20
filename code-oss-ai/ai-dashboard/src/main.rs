use std::env;
use std::process::Command;
use std::net::TcpStream;
use std::time::{Duration, Instant};
use std::io;
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph, Row, Table},
    Terminal,
};

struct Diagnostic {
    name: &'static str,
    #[allow(dead_code)]
    installed: bool,
    status_text: String,
    status_color: Color,
}

fn check_command(cmd: &str) -> bool {
    Command::new("which")
        .arg(cmd)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn check_ollama() -> (bool, String) {
    match TcpStream::connect_timeout(
        &"127.0.0.1:11434".parse().unwrap(),
        Duration::from_millis(40),
    ) {
        Ok(_) => (true, "Running (gemma4:e2b cached)".to_string()),
        Err(_) => (false, "Offline ('ollama serve' to start)".to_string()),
    }
}

fn check_gpu() -> (bool, String) {
    if !check_command("nvidia-smi") {
        return (false, "Not Detected (CPU-only Mode)".to_string());
    }

    let output = Command::new("nvidia-smi")
        .args([
            "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total",
            "--format=csv,noheader,nounits",
        ])
        .output();

    match output {
        Ok(out) if out.status.success() => {
            let s = String::from_utf8_lossy(&out.stdout).trim().to_string();
            let lines: Vec<&str> = s.lines().collect();
            if lines.is_empty() {
                (true, "Detected (NVIDIA GPU active)".to_string())
            } else {
                let first_line = lines[0];
                let parts: Vec<&str> = first_line.split(',').map(|p| p.trim()).collect();
                if parts.len() >= 5 {
                    let name = parts[0];
                    let util = parts[1];
                    let temp = parts[2];
                    let mem_used = parts[3];
                    let mem_total = parts[4];
                    let suffix = if lines.len() > 1 {
                        format!(" (+{} more)", lines.len() - 1)
                    } else {
                        "".to_string()
                    };
                    (
                        true,
                        format!(
                            "{} ({}% Util, {}°C, {}/{} MiB){}",
                            name, util, temp, mem_used, mem_total, suffix
                        ),
                    )
                } else {
                    (true, format!("Detected: {}", first_line))
                }
            }
        }
        _ => (false, "Error querying GPU status".to_string()),
    }
}

fn get_diagnostics() -> Vec<Diagnostic> {
    let mut diagnostics = Vec::new();

    // 1. Antigravity CLI & SDK (Primary / Preferred Harness)
    let ag_installed = check_command("antigravity") || check_command("agy");
    let has_gemini_key = env::var("GEMINI_API_KEY").is_ok();
    // Also check if gcloud is authenticated as a fallback
    let gcloud_auth = check_command("gcloud") && Command::new("gcloud")
        .args(["auth", "list", "--format=value(account)"])
        .output()
        .map(|o| !o.stdout.is_empty())
        .unwrap_or(false);
    let (status_text, status_color) = match (ag_installed, has_gemini_key || gcloud_auth) {
        (true, true) => ("Ready (GCP SDK & CLI active)".to_string(), Color::Green),
        (true, false) => ("Installed (Requires GCP auth / GEMINI_API_KEY)".to_string(), Color::Yellow),
        _ => ("Not Installed".to_string(), Color::Red),
    };
    diagnostics.push(Diagnostic {
        name: "Antigravity CLI (agy) [Primary]",
        installed: ag_installed,
        status_text,
        status_color,
    });

    // 2. Claude Code CLI
    let claude_installed = check_command("claude");
    let has_claude_key = env::var("ANTHROPIC_API_KEY").is_ok();
    let (status_text, status_color) = match (claude_installed, has_claude_key) {
        (true, true) => ("Ready (Authenticated)".to_string(), Color::Green),
        (true, false) => ("Installed (Missing ANTHROPIC_API_KEY)".to_string(), Color::Yellow),
        _ => ("Not Installed".to_string(), Color::Red),
    };
    diagnostics.push(Diagnostic {
        name: "Claude Code CLI",
        installed: claude_installed,
        status_text,
        status_color,
    });

    // 3. Gemini CLI
    let gemini_installed = check_command("gemini");
    let has_key = env::var("GEMINI_API_KEY").is_ok() || env::var("GOOGLE_API_KEY").is_ok();
    let (status_text, status_color) = match (gemini_installed, has_key) {
        (true, true) => ("Ready".to_string(), Color::Green),
        (true, false) => ("Installed (Missing GEMINI_API_KEY)".to_string(), Color::Yellow),
        _ => ("Not Installed".to_string(), Color::Red),
    };
    diagnostics.push(Diagnostic {
        name: "Gemini CLI",
        installed: gemini_installed,
        status_text,
        status_color,
    });

    // 4. Aider CLI
    let aider_installed = check_command("aider");
    let (status_text, status_color) = if aider_installed {
        ("Ready (CLI active)".to_string(), Color::Green)
    } else {
        ("Not Installed".to_string(), Color::Red)
    };
    diagnostics.push(Diagnostic {
        name: "Aider CLI",
        installed: aider_installed,
        status_text,
        status_color,
    });

    // 5. Ollama Local LLMs
    let (ollama_running, ollama_text) = check_ollama();
    let (status_text, status_color) = if check_command("ollama") {
        if ollama_running {
            (ollama_text, Color::Green)
        } else {
            (ollama_text, Color::Yellow)
        }
    } else {
        ("Not Installed".to_string(), Color::Red)
    };
    diagnostics.push(Diagnostic {
        name: "Ollama Local Service",
        installed: check_command("ollama"),
        status_text,
        status_color,
    });

    // 6. NVIDIA GPU Status
    let (gpu_detected, gpu_text) = check_gpu();
    let status_color = if gpu_detected {
        Color::Green
    } else {
        Color::Gray
    };
    diagnostics.push(Diagnostic {
        name: "NVIDIA GPU Status",
        installed: check_command("nvidia-smi"),
        status_text: gpu_text,
        status_color,
    });

    diagnostics
}

struct GcpContext {
    account: Option<String>,
    project: Option<String>,
    region: Option<String>,
}

fn get_gcp_context() -> GcpContext {
    if !check_command("gcloud") {
        return GcpContext {
            account: None,
            project: None,
            region: None,
        };
    }

    let account = Command::new("gcloud")
        .args(["config", "get-value", "core/account"])
        .output()
        .ok()
        .and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if s.is_empty() || s.contains("(unset)") || s.contains("unset") {
                None
            } else {
                Some(s)
            }
        });

    let project = Command::new("gcloud")
        .args(["config", "get-value", "project"])
        .output()
        .ok()
        .and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if s.is_empty() || s.contains("(unset)") || s.contains("unset") {
                None
            } else {
                Some(s)
            }
        });

    let region = Command::new("gcloud")
        .args(["config", "get-value", "compute/region"])
        .output()
        .ok()
        .and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if s.is_empty() || s.contains("(unset)") || s.contains("unset") {
                // Try fallback to zone
                Command::new("gcloud")
                    .args(["config", "get-value", "compute/zone"])
                    .output()
                    .ok()
                    .and_then(|o2| {
                        let s2 = String::from_utf8_lossy(&o2.stdout).trim().to_string();
                        if s2.is_empty() || s2.contains("(unset)") || s2.contains("unset") {
                            None
                        } else {
                            Some(s2)
                        }
                    })
            } else {
                Some(s)
            }
        });

    GcpContext {
        account,
        project,
        region,
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Perform fast diagnostics before loading full TUI screen
    let diagnostics = get_diagnostics();
    let gcp = get_gcp_context();

    // Check environment: if not in an interactive terminal, exit immediately
    if !crossterm::tty::IsTty::is_tty(&io::stdout()) {
        return Ok(());
    }

    // Set up terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let timeout_duration = Duration::from_secs(8);
    let start_time = Instant::now();
    let mut exit_code = 0; // 0 = exit to shell, 2 = request setup-ai

    loop {
        let elapsed = start_time.elapsed();
        if elapsed >= timeout_duration {
            break;
        }
        let seconds_left = timeout_duration.as_secs().saturating_sub(elapsed.as_secs());

        terminal.draw(|f| {
            let size = f.size();

            // Main vertical layout: Title, Content, Footer
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Length(5),  // Header banner
                    Constraint::Min(10),    // Body content
                    Constraint::Length(3),  // Help/Footer
                ])
                .split(size);

            // 1. HEADER BANNER
            let title_text = vec![
                Line::from(vec![
                    Span::raw(r"    ___    ____   _      __           __             __  _                 ").fg(Color::Magenta).bold(),
                ]),
                Line::from(vec![
                    Span::raw(r"   /   |  /  _/  | | /| / /___  _____/ /_______     / /_(_)___  ____  _____").fg(Color::Magenta).bold(),
                ]),
                Line::from(vec![
                    Span::raw(r"  / /| |  / /    | |/ |/ / __ \/ ___/ //_/ ___/    / __/ / __ \/ __ \/ ___/").fg(Color::Magenta).bold(),
                ]),
                Line::from(vec![
                    Span::raw(r" / ___ |_/ /_    |__/\__/ /_/ / /  / ,< (__  )    / /_/ / /_/ / / / (__  ) ").fg(Color::Magenta).bold(),
                ]),
                Line::from(vec![
                    Span::raw(r"/_/  |_/___/      \__/\__/\____/_/  /_/|_/____/     \__/_/\____/_/ /_/____/  ").fg(Color::Magenta).bold(),
                ]),
            ];
            let header = Paragraph::new(title_text).alignment(ratatui::layout::Alignment::Center);
            f.render_widget(header, chunks[0]);

            // 2. BODY PANELS (Split horizontally: Diagnostics on Left, Cheat sheet on Right)
            let body_chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([
                    Constraint::Percentage(55), // Diagnostics & GCP Context
                    Constraint::Percentage(45), // Help/Cheat sheet
                ])
                .split(chunks[1]);

            // 2A. LEFT COLUMN (Split vertically: Diagnostics on Top, GCP Context on Bottom)
            let left_chunks = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Length(9), // Diagnostics Table (6 items + borders = 8 lines)
                    Constraint::Min(5),    // GCP Context Panel
                ])
                .split(body_chunks[0]);

            // 2A1. SYSTEM DIAGNOSTICS TABLE
            let mut rows = Vec::new();
            for diag in &diagnostics {
                let symbol = match diag.status_color {
                    Color::Green => "  🟢  ",
                    Color::Yellow => "  🟡  ",
                    Color::Gray => "  ⚪  ",
                    _ => "  🔴  ",
                };
                rows.push(Row::new(vec![
                    Span::styled(format!(" {:-<23}", diag.name), Style::default().bold()),
                    Span::styled(symbol, Style::default()),
                    Span::styled(&diag.status_text, Style::default().fg(diag.status_color)),
                ]));
            }

            let diag_table = Table::new(
                rows,
                [
                    Constraint::Length(25),
                    Constraint::Length(6),
                    Constraint::Min(25),
                ],
            )
            .block(
                Block::default()
                    .title(" AI Toolchain Diagnostics ")
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Cyan)),
            );
            f.render_widget(diag_table, left_chunks[0]);

            // 2A2. GOOGLE CLOUD CONTEXT PANEL
            let mut gcp_text = Vec::new();
            gcp_text.push(Line::from(""));

            let account_span = match &gcp.account {
                Some(acc) => Span::styled(acc, Style::default().fg(Color::Green).bold()),
                None => Span::styled("Not Authenticated (Run setup-ai)", Style::default().fg(Color::Red).bold()),
            };
            gcp_text.push(Line::from(vec![
                Span::raw("  👤 Account:  ").fg(Color::White).bold(),
                account_span,
            ]));

            let project_span = match &gcp.project {
                Some(proj) => Span::styled(proj, Style::default().fg(Color::Green).bold()),
                None => Span::styled("Not Configured", Style::default().fg(Color::Yellow).bold()),
            };
            gcp_text.push(Line::from(vec![
                Span::raw("  📁 Project:  ").fg(Color::White).bold(),
                project_span,
            ]));

            let region_span = match &gcp.region {
                Some(reg) => Span::styled(reg, Style::default().fg(Color::Green).bold()),
                None => Span::styled("Not Configured", Style::default().fg(Color::Yellow).bold()),
            };
            gcp_text.push(Line::from(vec![
                Span::raw("  📍 Location: ").fg(Color::White).bold(),
                region_span,
            ]));

            let gcp_block = Paragraph::new(gcp_text).block(
                Block::default()
                    .title(" Google Cloud Active Context ")
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Cyan)),
            );
            f.render_widget(gcp_block, left_chunks[1]);

            // 2B. RIGHT PANEL: CHEAT SHEET & QUICK LINKS
            let cheat_text = vec![
                Line::from(""),
                Line::from(vec![
                    Span::raw("  🚀 Preferred AI Harness:").bold().fg(Color::LightMagenta),
                ]),
                Line::from(vec![
                    Span::raw("   • agy                ").bold().fg(Color::Green),
                    Span::raw("Trigger primary Gemini AI pipeline"),
                ]),
                Line::from(""),
                Line::from(vec![
                    Span::raw("  ⚡ CLI Assistants:").bold().fg(Color::LightMagenta),
                ]),
                Line::from(vec![
                    Span::raw("   • claude             ").bold().fg(Color::White),
                    Span::raw("Launch Anthropic agentic coding"),
                ]),
                Line::from(vec![
                    Span::raw("   • aider              ").bold().fg(Color::White),
                    Span::raw("Run elite terminal Git agent"),
                ]),
                Line::from(""),
                Line::from(vec![
                    Span::raw("  🧠 Local Gemma 4 Model:").bold().fg(Color::LightMagenta),
                ]),
                Line::from(vec![
                    Span::raw("   • ollama run gemma4:e2b ").bold().fg(Color::Green),
                    Span::raw("Start local coding LLM"),
                ]),
                Line::from(""),
                Line::from(vec![
                    Span::raw("  🔑 Secure Key Storage:").bold().fg(Color::LightMagenta),
                ]),
                Line::from(vec![
                    Span::raw("   • setup-ai           ").bold().fg(Color::Yellow),
                    Span::raw("Fetch/set persistent API keys"),
                ]),
            ];
            let cheat_sheet = Paragraph::new(cheat_text).block(
                Block::default()
                    .title(" AI Command Center Help ")
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Cyan)),
            );
            f.render_widget(cheat_sheet, body_chunks[1]);

            // 3. FOOTER
            let footer_text = vec![
                Line::from(vec![
                    Span::raw(" [ANY KEY / ENTER]").bold().fg(Color::Green),
                    Span::raw(" Shell  | "),
                    Span::raw(" [S]").bold().fg(Color::Yellow),
                    Span::raw(" Run setup-ai  | "),
                    Span::raw(" [Q]").bold().fg(Color::Red),
                    Span::raw(" Quit to terminal  "),
                    Span::raw(format!("(Auto-exit in {}s...)", seconds_left)).fg(Color::Gray).italic(),
                ]),
            ];
            let footer = Paragraph::new(footer_text)
                .alignment(ratatui::layout::Alignment::Center)
                .block(
                    Block::default()
                        .borders(Borders::TOP)
                        .border_style(Style::default().fg(Color::DarkGray)),
                );
            f.render_widget(footer, chunks[2]);
        })?;

        // Poll for inputs (non-blocking so the timer ticks)
        if event::poll(Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char('s') | KeyCode::Char('S') => {
                        exit_code = 2; // Signal shell to run setup-ai
                        break;
                    }
                    KeyCode::Char('q') | KeyCode::Char('Q') => {
                        break;
                    }
                    _ => {
                        // Any other key exits to shell immediately
                        break;
                    }
                }
            }
        }
    }

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    // Exit with code indicating what the user wanted
    std::process::exit(exit_code);
}
