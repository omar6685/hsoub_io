namespace :creator do
  task create_communities: :environment do
    Community.create(name: 'تطوير الويب', description: 'مجتمع خاص بمناقشة وطرح المواضيع والقضايا العامة المتعلقة بتطوير الويب ولغاتها المختلفة')
    Community.create(name: 'التدوين وصناعة المحتوى', description: 'هنا نسعى للخروج بأفكار ونقاشات تفيد الكاتب المخضرم والجديد لبناء محتوى أفضل.')
    Community.create(name: 'ريادة الاعمال', description: 'مجتمع المهتمين بريادة الأعمال وإنشاء مشاريعهم الخاصة.')
  end

  task create_topics: :environment do
    post = Post.create(title: 'تصميم واجهة المستخدم الأمامية ... هل من طرق و أفكار مساعدة للمبتدئين؟', user: User.first, community: Community.second)
    Topic.create(text: 'أنا حاليا مبتدأ في تصميم الواجهات الأمامية باللغات الوصفية html و css ... حاليا أواجه بعض الصعوبات في التصميم الدقيق للأشياء(Layouts) .. لم أنتقل بعد إلى flexbox و grid ... هل من طرق أو تقنيات مساعدة للمبتدئين أمثالي؟', post: post)

    post = Post.create(title: 'هل نشر مقال في موقع من كتاب يعتبر انتهاك حقوق؟', user: User.first, community: Community.third)
    Topic.create(text: 'لو اخدت مقال من كتاب حرفيا كما هو ثم نشرته في أحد المواقع او المدونات يعتبر انتهاك حقوق؟', post: post)

    post = Post.create(title: 'إنشاء شركتك الخاصة أمر صعب جدا !!', user: User.first, community: Community.fourth)
    Topic.create(text: '"-إنشاء شركتك الخاصة أمر صعب جدا يكاد يكون مستحيلا !!- ... أظن أن ما قلته للتو لم يحفزكم و أحبطكم... آسف سأعيد صياغته بطريقة أخرى ..... -إن كنت تنتظر التحفيز للقيام بأي شيئ فلا تفعل- "', post: post)
  end
end
