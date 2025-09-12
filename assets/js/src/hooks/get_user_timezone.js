export default {
  mounted() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    this.pushEventTo("#invitation-form", "user_timezone", { timezone: timezone });
  },
};
