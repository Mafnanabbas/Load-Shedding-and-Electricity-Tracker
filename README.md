# Load Shedding and Electricity Tracker

**Course:** Software Engineering
**Project type:** Full-stack web application (Python/Django and Supabase)

---

## 1. Project Title

**Load Shedding and Electricity Tracker (LSET): A Web System for Load-Shedding Schedules and Power Quality Monitoring**

---

## 2. Problem Statement

Electricity consumers currently lack a centralized and reliable platform to monitor load-shedding schedules and track power quality. This makes it difficult to plan daily activities or to protect appliances from unsafe supply conditions.

The Load Shedding and Electricity Tracker solves this by providing a unified web application where users can view location-specific load-shedding schedules, check the current electricity status, and receive alerts about abnormal power conditions: **over-voltage, under-voltage and phase shift**.

---

## 3. Functional Requirements

1. **User management:** new users can register and existing users can log in securely to access protected features.
2. **Area selection:** users select their area to see relevant schedules and data.
3. **Schedule management:** administrators can add, update and delete load-shedding schedules; users can view the schedule for their selected area.
4. **Status and monitoring display:** the system displays the current electricity status, current and historical voltage readings, and phase information.
5. **Abnormality detection:** the system detects and logs
   - under-voltage (below the minimum limit),
   - over-voltage (above the maximum limit),
   - phase-shift conditions,
   based on recorded data.
6. **Alert generation:** the system generates alerts for abnormal electrical conditions.
7. **Reporting:** the system provides reports and graphical statistics from stored historical data (schedules, electricity status, voltage and phase information).
8. **Access control:** administrative functions such as modifying data are restricted to authorized administrators through an admin dashboard.

---

## 4. Non-Functional Requirements

- **Performance:** responds to requests within a reasonable time, supports multiple concurrent users, uses optimized database queries, and loads reports and graphs efficiently.
- **Security:** user authentication, securely stored passwords, input validation, and protection of administrative and protected resources from unauthorized access.
- **Reliability and availability:** accurate and consistent database records, proper handling of invalid input with clear error messages, prevention of data loss where possible, and availability whenever the underlying services (server, database, network) are operational.
- **Usability:** a simple, easy-to-navigate interface that is responsive on different screen sizes and uses understandable terms to show electricity and abnormal-voltage status.
- **Scalability:** the architecture supports adding more users, areas, electricity records, monitoring features, sensors and data sources in the future.

---

## 5. Users / Actors

| Actor | Responsibilities |
|---|---|
| **Normal User** | Registers, selects an area, views load-shedding schedules, checks electricity, voltage and phase status, and views alerts and historical reports |
| **Administrator** | Manages system data: adds, modifies and deletes load-shedding schedules; manages electricity status, voltage readings, phase information and alerts; generates reports |

---

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript (Django templates, or a framework such as React/Vue) with a chart library for graphs |
| Backend | Python with the Django framework |
| Database | Supabase (PostgreSQL) |
| Version control | Git and GitHub |

**Future scope:** machine learning libraries (Scikit-learn, TensorFlow or PyTorch) for predictive load shedding, to be decided after the core project is complete.

---

## 7. Technology Justification

- **Python and Django (backend):** Python is readable and fast to develop in, which suits a lab project. Django is a "batteries-included" framework that provides built-in user authentication, an admin interface (which directly satisfies the admin dashboard requirement), an ORM, and secure request handling. Python is also the standard language for machine learning, so predictive features can be added later without changing languages.
- **Supabase (database):** Supabase provides a scalable PostgreSQL database as a managed service, which removes most database setup and maintenance work so the team can focus on application logic. Django connects to it as a standard PostgreSQL database, and Supabase also offers real-time features that could be used for live alerts later.
- **HTML, CSS and JavaScript (frontend):** standard web technologies let us build the responsive, user-friendly interface required by the usability requirements, and chart libraries make graphs and statistics load efficiently on different screen sizes.
- **Git and GitHub:** support team collaboration and version history.
