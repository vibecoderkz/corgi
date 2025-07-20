class OnboardingModel {
  final String title;
  final String subtitle;
  final String? imagePath;
  final bool isWelcome;
  final bool isCallToAction;

  OnboardingModel({
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.isWelcome = false,
    this.isCallToAction = false,
  });

  static List<OnboardingModel> getOnboardingData() {
    return [
      OnboardingModel(
        title: "Corgi",
        subtitle: "изучай ИИ. Создавай. Делись. Расти.",
        isWelcome: true,
      ),
      OnboardingModel(
        title: "Практичные уроки по ИИ инструментам",
        subtitle: "Изучай современные инструменты искусственного интеллекта через практические задания и проекты",
        imagePath: "lib/images/onboardingOne.png",
      ),
      OnboardingModel(
        title: "Зарабатывай баллы за активность",
        subtitle: "Получай баллы за выполнение заданий и обменивай их на скидки на курсы",
        imagePath: "lib/images/onboardingTwo.png",
      ),
      OnboardingModel(
        title: "Присоединяйся к коммьюнити",
        subtitle: "Делись своими проектами с единомышленниками и получай обратную связь",
        imagePath: "lib/images/onboardingThree.png",
      ),
      OnboardingModel(
        title: "Начни обучение прямо сейчас",
        subtitle: "Присоединяйся к тысячам студентов, которые уже изучают ИИ с Corgi",
        imagePath: "lib/images/onboardingFour.png",
        isCallToAction: true,
      ),
    ];
  }
}