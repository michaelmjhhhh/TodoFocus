import { getTodos, getLists } from "@/actions/todos";
import { AppShell } from "@/components/AppShell";

export const dynamic = "force-dynamic";

export default async function Home() {
  const [todos, lists] = await Promise.all([getTodos(), getLists()]);

  return <AppShell todos={todos} lists={lists} />;
}
